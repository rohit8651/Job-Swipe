import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:parser/view/auth/login_screen.dart';
import 'package:parser/view/nav/wrapper.dart';

import '../../const/colors.dart';
import '../../controller/login_controller.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  final LoginController controller = Get.put(LoginController());
  int currentIndex = 0;


  void _checkLoginStatus() {
    if (controller.auth.currentUser != null) {
      controller.loadUser();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => currentIndex = index),
            children: [
              _SplashPage(
                title: 'Welcome to AI Job Swipe',
                subtitle: 'Your intelligent job discovery assistant.',
                animation: 'assets/welcome.json',
                button: TextButton(
                  onPressed: _checkLoginStatus,
                  child: const Text("Skip"),
                ),
              ),
              _SplashPage(
                title: 'Scan & Match',
                subtitle: 'Scan your resume and get the perfect job match!',
                animation: 'assets/search.json',
                button: ElevatedButton(
                  onPressed: _checkLoginStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentIndex == index ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        currentIndex == index ? AppColors.text : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String animation;
  final Widget button;

  const _SplashPage({
    required this.title,
    required this.subtitle,
    required this.animation,
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(animation, width: 250, height: 250, fit: BoxFit.contain),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.text.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 40),
          button,
        ],
      ),
    );
  }
}
