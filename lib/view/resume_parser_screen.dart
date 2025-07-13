import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:parser/const/colors.dart';
import 'package:parser/controller/login_controller.dart';
import 'package:parser/modals/user.dart' as user_modal;
import 'package:parser/view/drawer/resume_scans.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';


class ResumeParserScreen extends StatefulWidget {
  final LoginController controller = Get.find<LoginController>();
  final user_modal.Resume resume;
  final void Function(List<String> roles)? onRolesApplied; // <-- Add this

  ResumeParserScreen({super.key, required this.resume, this.onRolesApplied});

  @override
  // ignore: library_private_types_in_public_api
  _ResumeParserScreenState createState() => _ResumeParserScreenState();
}

class _ResumeParserScreenState extends State<ResumeParserScreen> {
  var isLoading = false.obs;
  var jobLoading = false.obs;

  var extractedText = "No text extracted yet.".obs;

  final String apiKey =
      "AIzaSyDxgUYiBKZN2liKNg6HLlyS7jiTm0aIHGs"; // Replace with your key

  @override
  void initState() {
    super.initState();
    // Automatically trigger file picker and resume processing when screen loads
    // Future.delayed(Duration.zero, () async {
    //   await pickAndExtractText();
    // });
  }

  void saveResumeToFirestore() {
    final resumes = widget.controller.userAccount.resumes;

    if (resumes.length >= 5) {
      // Remove the oldest one if more than 5
      resumes.removeAt(0);
    }

    resumes.add(widget.resume);
    widget.controller.updateDoc(widget.controller.userAccount);
  }

  Future<void> pickAndExtractText() async {
    isLoading.value = true;

    // Clear previous values
    widget.resume.name.value = "Not Found";
    widget.resume.email.value = "Not Found";
    widget.resume.phone.value = "Not Found";
    widget.resume.skills.value = "Not Found";
    widget.resume.education.value = "Not Found";
    widget.resume.projects.value = "Not Found";
    widget.resume.jobRoles.clear();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // Important for web!
    );

    if (result != null) {
      Uint8List? fileBytes;
      if (kIsWeb) {
        fileBytes = result.files.single.bytes;
      } else {
        final path = result.files.single.path;
        if (path != null) {
          fileBytes = await File(path).readAsBytes();
        }
      }

      if (fileBytes != null) {
        await extractAndParseText(fileBytes); // Pass bytes, not File
        await roleUsingGemini();
        // Navigation logic here if needed
      }
    }

    isLoading.value = false;
  }

  Future<void> extractAndParseText(Uint8List fileBytes) async {
    isLoading.value = true;
    try {
      final PdfDocument document = PdfDocument(
        inputBytes: fileBytes,
      );

      String text = PdfTextExtractor(document).extractText();
      document.dispose();

      extractedText.value = text;

      await extractUsingGeminiAI(text);
    } catch (e) {
      extractedText.value = "Error extracting text: $e";
    }
    isLoading.value = false;
  }

  Future<void> extractUsingGeminiAI(String text) async {
    isLoading.value = true;

    final Uri url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-lite:generateContent?key=$apiKey",
    );

    final Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text": """
Extract the following details from the resume text:
- Name
- Email
- Phone number
- Skills
- Education
- Projects (title & description)

Return the response in JSON format without any extra characters:
{
  "name": "John Doe",
  "email": "johndoe@gmail.com",
  "phone": "+1-234-567-890",
  "skills": ["Flutter", "Dart", "Firebase"],
  "education": "Bachelor's in Computer Science, XYZ University",
  "projects": [
    {
      "title": "Weather App",
      "description": "Developed a Flutter-based weather app using OpenWeather API."
    },
    {
      "title": "E-commerce Website",
      "description": "Built a full-stack e-commerce platform using React and Node.js."
    }
  ]
}

Resume Text:
$text
""",
            },
          ],
        },
      ],
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> result = jsonDecode(response.body);

        if (result.containsKey('candidates') &&
            result['candidates'].isNotEmpty) {
          String content =
              result['candidates'][0]['content']['parts'][0]['text'];

          content = content.replaceAll(RegExp(r'```json|```'), '').trim();

          try {
            Map<String, dynamic> extractedData = jsonDecode(content);
            parseEntities(extractedData);
          } catch (jsonError) {
            if (kDebugMode) {
              print("JSON Parsing Error: $jsonError. Cleaned Response: $content");
            }
          }
        } else {
          if (kDebugMode) {
            print("API Response Format Unexpected: ${response.body}");
          }
        }
      } else {
        if (kDebugMode) {
          print("API Error: ${response.body}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("API Request Failed: $e");
      }
    }

    isLoading.value = false;
  }

  void parseEntities(Map<String, dynamic> response) {
    isLoading.value = true;

    if (response.containsKey("name")) {
      widget.resume.name.value = response["name"];
    }
    if (response.containsKey("email")) {
      widget.resume.email.value = response["email"];
    }
    if (response.containsKey("phone")) {
      widget.resume.phone.value = response["phone"];
    }
    if (response.containsKey("skills")) {
      widget.resume.skills.value = response["skills"].join(", ");
    }
    if (response.containsKey("education")) {
      widget.resume.education.value = response["education"];
    }

    if (response.containsKey("projects")) {
      widget.resume.projects.value = response["projects"]
          .map<String>((project) {
            return "${project['title']}: ${project['description']}";
          })
          .toList()
          .join("\n");
    }

    isLoading.value = false;
  }

  Future<void> roleUsingGemini() async {
    jobLoading.value = true;

    final Uri url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-lite:generateContent?key=$apiKey",
    );

    final Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text": """
Based on the following skills, education, and projects, suggest top 4 relevant job roles. Include both general and specific roles.
Only return job role names — no examples, no descriptions, no slashes.

### Skills:
${widget.resume.skills}

### Education:
${widget.resume.education}

### Projects:
${widget.resume.projects}

Return the response in JSON format:
{
  "job_roles": [
    "role 1",
    "role 2",
    "role 3"
    "role 4"
  ]
}
""",
            },
          ],
        },
      ],
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> result = jsonDecode(response.body);

        if (result.containsKey('candidates') &&
            result['candidates'].isNotEmpty) {
          String content =
              result['candidates'][0]['content']['parts'][0]['text'];

          content = content.replaceAll(RegExp(r'```json|```'), '').trim();

          try {
            Map<String, dynamic> extractedData = jsonDecode(content);
            if (extractedData.containsKey("job_roles")) {
              widget.resume.jobRoles.assignAll(
                List<String>.from(extractedData["job_roles"]),
              );
              saveResumeToFirestore();

              // Call the callback to trigger navigation and search
              if (widget.onRolesApplied != null) {
                widget.onRolesApplied!(widget.resume.jobRoles.toList());
              }
            }
          } catch (jsonError) {
            if (kDebugMode) {
              print("JSON Parsing Error: $jsonError. Cleaned Response: $content");
            }
          }
        } else {
          if (kDebugMode) {
            print("API Response Format Unexpected: ${response.body}");
          }
        }
      } else {
        if (kDebugMode) {
          print("API Error: ${response.body}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("API Request Failed: $e");
      }
    }

    jobLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        title: Text(
          'AI Resume Parser',
          style: TextStyle(color: AppColors.text),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              await widget.controller.loadUser();
              setState(() {});
            },
            icon: Icon(Icons.refresh),
          ),
          IconButton(
            icon: Icon(Icons.scanner),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ResumeScansScreen(),
              ));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.refresh,
        onRefresh: () => widget.controller.loadUser(),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 30),
              Obx(
                () => Center(
                  child: Text(
                    "Welcome, ${widget.controller.userAccount.name.value} 😊",
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
    
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                    side: BorderSide(color: Colors.white, width: 1),
                  ),
                  backgroundColor: AppColors.buttonBackground,
                ),
                onPressed: () async {
                  await pickAndExtractText();
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Pick & Parse Resume",
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  "📝 Extracted Info",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              paresInfo(isLoading, widget),

              SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.resume.skills.value == "No data" ||
                        widget.resume.skills.value.isEmpty ||
                        widget.resume.skills.value == "Not Found") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.error,
                          content: Text(
                            'Extract Info first',
                            style: TextStyle(color: AppColors.text),
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      if (kDebugMode) {
                        print('Neww');
                      }
                      Get.defaultDialog(
                        backgroundColor: AppColors.buttonBackground,
                        title: "Confirm Save",
                        middleText: "Are you sure to save data?",
                        textConfirm: "Yes",
                        confirmTextColor: AppColors.success,
                        textCancel: "No",
                        cancelTextColor: AppColors.error,
                        onConfirm: () {
                          final resumes = widget.controller.userAccount.resumes;

                          if (resumes.length >= 5) {
                            Get.defaultDialog(
                              backgroundColor: AppColors.error,
                              title: "Limit Exceeded",
                              middleText:
                                  "Only 5 resumes can be saved. Do you want to replace the oldest one?",
                              textConfirm: "Yes",
                              textCancel: "No",
                              onConfirm: () {
                                resumes.removeAt(0); // Remove the oldest
                                resumes.add(widget.resume);
                                widget.controller.updateDoc(
                                  widget.controller.userAccount,
                                );
                                Get.back(); // Close the dialog
                                Get.back(); // Go back after saving
                              },
                              onCancel: () {},
                            );
                          } else {
                            resumes.add(widget.resume);
                            widget.controller.updateDoc(
                              widget.controller.userAccount,
                            );
                            Get.back(); // Go back after saving
                          }
                        },
                      );
                    }
                  },
                  child: Text(
                    "Save Data",
                    style: TextStyle(color: AppColors.text),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Button to fetch job roles
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                    side: BorderSide(color: Colors.white, width: 1),
                  ),
                  backgroundColor: AppColors.buttonBackground,
                ),
                onPressed: () async {
                  if (widget.resume.skills.value == "Not Found" ||
                      widget.resume.skills.value == "No data" ||
                      widget.resume.skills.value.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.error,
                        content: Text(
                          'Extract Info first',
                          style: TextStyle(color: AppColors.text),
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    await roleUsingGemini();
                  }
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:
                      jobLoading.value
                          ? Text(
                            "Getting...",
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : Text(
                            "Get Job Roles",
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),

              SizedBox(height: 20),

              // Displaying Suggested Job Roles
              if (widget.resume.jobRoles.isNotEmpty) ...[
                Center(
                  child: Text(
                    "🎯 Suggested Job Roles",
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Flexible(
                  child: Container(
                    width: double.maxFinite,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.container,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child:
                        jobLoading.value
                            ? Center(
                              child: CircularProgressIndicator(
                                color: AppColors.indicator,
                              ),
                            )
                            : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10),
                                  ...widget.resume.jobRoles.map(
                                    (role) => TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: AppColors.text,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(100),
                                          side: BorderSide(
                                            color: AppColors.success,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        if (widget.onRolesApplied != null) {
                                          widget.onRolesApplied!(widget.resume.jobRoles.toList());
                                        }
                                      },
                                      child: Text(
                                        "- $role",
                                        style: TextStyle(
                                          color: AppColors.buttonBackground,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}



Widget paresInfo(RxBool isLoading, ResumeParserScreen widget) {
  return Flexible(
    child: Obx(
      () => Container(
        width: double.maxFinite,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.container,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child:
            isLoading.value
                ? Center(
                  child: CircularProgressIndicator(color: AppColors.indicator),
                )
                : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "🤵🏻 Name:\n",
                              style: TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text: widget.resume.name.value,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "\n📧 Email:\n",
                              style: TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text: widget.resume.email.value,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "\n📞 Phone:\n",
                              style: TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text: widget.resume.phone.value,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "\n🛠️ Skills:\n",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.text,
                              ),
                            ),
                            TextSpan(
                              text: widget.resume.skills.value,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "\n🎓 Education:\n",
                              style: TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text: widget.resume.education.value,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "\n💼 Projects:\n",
                              style: TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text: widget.resume.projects.value,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    ),
  );
}
