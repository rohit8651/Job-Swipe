import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parser/const/colors.dart';
import 'package:parser/controller/login_controller.dart';
import 'package:parser/modals/user.dart';

import '../resume_parser_screen.dart';

class ResumeScansScreen extends StatelessWidget {
  final LoginController controller = Get.find<LoginController>();
  final RxList<Resume> resumes = <Resume>[].obs;

  ResumeScansScreen({super.key}) {
    // Load your resumes here from Firebase or local cache
    controller.loadUser();
    resumes.assignAll(controller.userAccount.resumes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scanned Resumes'),
        centerTitle: true,
        backgroundColor: AppColors.scaffold,
        foregroundColor: AppColors.text,
      ),
      body: SafeArea(
        child: Obx(() {
          if (resumes.isEmpty) {
            return Center(
              child: Text(
                'No resumes found.',
                style: TextStyle(color: AppColors.text, fontSize: 18),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: resumes.length,
            itemBuilder: (context, index) {
              return _buildResumeCard(resumes[index]);
            },
          );
        }),
      ),
    );
  }

  Widget _buildResumeCard(Resume resume) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.container,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetail("📛 Name:", resume.name.value),
          _buildDetail("📧 Email:", resume.email.value),
          _buildDetail("📞 Phone:", resume.phone.value),
          _buildDetail("🛠️ Skills:", resume.skills.value),
          _buildDetail("🎓 Education:", resume.education.value),
          _buildDetail("💼 Projects:", resume.projects.value),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Use this"),
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.text,
                backgroundColor: AppColors.buttonBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Get.offAll(ResumeParserScreen(resume: resume));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label\n",
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                // ignore: deprecated_member_use
                color: AppColors.text.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
