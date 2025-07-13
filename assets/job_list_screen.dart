import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:parser/const/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class JobListScreen extends StatefulWidget {
  final String searchQuery;
  const JobListScreen({super.key, required this.searchQuery});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  List jobs = [];
  bool isLoading = false;
  bool isError = false;
  String location = "India";

  late List<String> searchQueries;
  final TextEditingController _searchController = TextEditingController();

  Set<String> likedJobs = {};
  Set<String> watchLaterJobs = {};

  List<SwipeItem> _swipeItems = [];
  late MatchEngine _matchEngine;

final String userId = FirebaseAuth.instance.currentUser!.uid; // Replace with FirebaseAuth.currentUser!.uid

  @override
  void initState() {
    super.initState();
    searchQueries = _parseSearchQuery(widget.searchQuery);
    _searchController.text = widget.searchQuery;
    fetchJobs();
  }

  List<String> _parseSearchQuery(String query) {
    return query
        .split(',')
        .map((e) => e.trim().toLowerCase().replaceAll(' ', '_'))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> fetchJobs() async {
    setState(() {
      isLoading = true;
      isError = false;
      jobs.clear();
    });

    try {
      Set<String> seenJobIds = {};
      List<dynamic> allJobs = [];

      for (String query in searchQueries) {
        final DocumentSnapshot snapshot =
            await FirebaseFirestore.instance.collection('jobs').doc(query).get();

        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final List<dynamic> cachedJobs = data['jobs'] ?? [];

          for (var job in cachedJobs) {
            final jobId = job['job_id'].toString();
            if (!seenJobIds.contains(jobId)) {
              seenJobIds.add(jobId);
              allJobs.add(job);
            }
          }
        }
      }

      _swipeItems = allJobs.map((job) {
        return SwipeItem(
          content: job,
          likeAction: () async {
            likedJobs.add(job['job_id'].toString());
            await _saveJobToFirestore(job, 'liked');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Liked")));
          },
          nopeAction: () async {
            watchLaterJobs.add(job['job_id'].toString());
            await _saveJobToFirestore(job, 'watchLater');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to Watch Later")));
          },
        );
      }).toList();

      _matchEngine = MatchEngine(swipeItems: _swipeItems);

      if (mounted) {
        setState(() {
          jobs = allJobs;
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Firebase fetch error: $e');
      if (mounted) {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    }
  }


  Future<void> _saveJobToFirestore(Map<String, dynamic> job, String category) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(category)
        .doc(job['job_id'].toString())
        .set(job);
  }

Future<void> fetchAndStoreFromAPI(String query) async {
  final apiKey = '4321f8b85cmsh82d7d2b93326672p1387eajsn81ddd81c817f';
  // final offset = 0;
  final encodedTitle = Uri.encodeComponent(query.replaceAll('_', ' '));
  final encodedLocation = Uri.encodeComponent(location);

final url = Uri.parse(
  'https://jsearch.p.rapidapi.com/search?query=$encodedTitle&location=$encodedLocation',
);

  try {
    final response = await http.get(url, headers: {
      'x-rapidapi-key': apiKey,
      'x-rapidapi-host': 'jsearch.p.rapidapi.com',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> fetchedJobs = responseData['data'] ?? [];

      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(query)
          .set({'jobs': fetchedJobs});
    } else {
      throw Exception('API error ${response.statusCode}');
    }
  } catch (e) {
    if (kDebugMode) print("API fetch error: $e");
  }
}



  void _onSearch() async {
    final rawInput = _searchController.text.trim();
    if (rawInput.isNotEmpty) {
      final queries = _parseSearchQuery(rawInput);
      setState(() {
        searchQueries = queries;
        isLoading = true;
        isError = false;
      });

      for (final query in queries) {
        final doc = await FirebaseFirestore.instance.collection('jobs').doc(query).get();
        if (!doc.exists) {
          await fetchAndStoreFromAPI(query);
        }
      }

      fetchJobs();
    }
  }

Widget buildJobCard(dynamic job) {
    final String title = job['job_title'] ?? 'No Title';
    final String company = job['employer_name'] ?? 'Unknown';
    final String location = job['job_location'] ?? 'Unknown';
    final String jobType = (job['job_employment_types'] as List?)?.join(', ') ?? 'N/A';
    final String description = job['job_description'] ?? 'No description available.';
    final String? url = job['job_apply_link'];


    return Center(
      child: Card(
        color: AppColors.buttonBackground,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.text),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 12),
                Text("\uD83C\uDFE2 Company: $company", style: TextStyle(color: AppColors.text)),
                const SizedBox(height: 8),
                Text("\uD83D\uDCCD Location: $location", style: TextStyle(color: AppColors.text)),
                const SizedBox(height: 8),
                Text("\uD83D\uDCBC Job Type: $jobType", style: TextStyle(color: AppColors.text)),
                const SizedBox(height: 8),
                Text("\uD83D\uDCDD Description:", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)),
                Text(description, maxLines: 8, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.text)),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (url != null && url.isNotEmpty) {
                        final Uri uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not launch URL")));
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                      child: Text("Apply Now", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        likedJobs.add(job['job_id'].toString());
                        await _saveJobToFirestore(job, 'liked');
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added to Liked")));
                      },
                      icon: Icon(Icons.favorite),
                      label: Text("Like"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        watchLaterJobs.add(job['job_id'].toString());
                        await _saveJobToFirestore(job, 'watchLater');
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved for Later")));
                      },
                      icon: Icon(Icons.bookmark),
                      label: Text("Watch Later"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        centerTitle: true,
        title: Text('Job Swiper', style: TextStyle(color: AppColors.text, fontSize: 22)),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => SavedJobsScreen(category: 'liked', userId: userId),
              ));
            },
          ),
          IconButton(
            icon: Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => SavedJobsScreen(category: 'watchLater', userId: userId),
              ));
            },
          ),
          IconButton(icon: Icon(Icons.search), onPressed: _onSearch),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _onSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search job roles',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.success))
                : isError
                    ? Center(child: Text('Error loading jobs'))
                    : SwipeCards(
                        matchEngine: _matchEngine,
                        itemBuilder: (context, index) {
                          final job = _swipeItems[index].content;
                          return buildJobCard(job);
                        },
                        onStackFinished: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No more jobs")));
                        },
                        upSwipeAllowed: false,
                        fillSpace: true,
                      ),
          ),
        ],
      ),
    );
  }
}

class SavedJobsScreen extends StatelessWidget {
  final String category; // 'liked' or 'watchLater'
  final String userId;

  const SavedJobsScreen({super.key, required this.category, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${category == 'liked' ? 'Liked' : 'Watch Later'} Jobs')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(category)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final jobs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(job['job_title'] ?? 'No title'),
                  subtitle: Text(job['organization'] ?? ''),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    final url = job['url'];
                    if (url != null) {
                      launchUrl(Uri.parse(url));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
