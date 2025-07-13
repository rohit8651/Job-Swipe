import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parser/const/colors.dart';
import 'package:parser/controller/login_controller.dart';
import 'package:parser/view/auth/signup_screen.dart';

class LoginScreen extends StatelessWidget {
  final LoginController controller = Get.put(LoginController());

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo or Icon
              Hero(
                tag: "logo",
                child: Icon(
                  Icons.work_outline,
                  size: 80,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Login to your account to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.text.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),

              /// Email
              Obx(
                () => TextField(
                  keyboardType: TextInputType.emailAddress,
                  controller: controller.email,
                  onChanged: (value) => controller.emailText.value = value,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.container,
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.text),
                    suffixIcon: controller.emailText.isNotEmpty
                        ? IconButton(
                            onPressed: controller.clearEmail,
                            icon: Icon(Icons.clear, color: AppColors.error),
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  style: TextStyle(color: AppColors.text),
                  cursorColor: AppColors.text,
                ),
              ),
              const SizedBox(height: 20),

              /// Password
              Obx(
                () => TextField(
                  keyboardType: TextInputType.visiblePassword,
                  controller: controller.pass,
                  obscureText: !controller.isPasswordVisible.value,
                  onChanged: (value) => controller.passText.value = value,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.container,
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.text),
                    suffixIcon: IconButton(
                      onPressed: controller.togglePasswordVisibility,
                      icon: Icon(
                        controller.isPasswordVisible.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.error,
                      ),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  style: TextStyle(color: AppColors.text),
                  cursorColor: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),

              /// Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {}, // Add your logic here
                  child: Text('Forgot Password?', style: TextStyle(color: AppColors.error)),
                ),
              ),

              /// Login Button
              const SizedBox(height: 10),
              Obx(
                () => ElevatedButton(
                  onPressed: () {
                    if (controller.email.text.isEmpty || controller.pass.text.isEmpty) {
                      Get.snackbar(
                        'Login Error',
                        'Email or Password cannot be empty.',
                        backgroundColor: AppColors.error,
                        colorText: Colors.white,
                      );
                    } else {
                      controller.login();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 6,
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Log In', style: TextStyle(color: AppColors.text, fontSize: 16)),
                ),
              ),

              /// Sign Up Navigation
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  controller.clearAll();
                  Get.to(() => SignupScreen());
                },
                child: Text(
                  "Don't have an account? Create now",
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              /// Divider
              const SizedBox(height: 30),
              Row(
                children: [
                  const Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text("or", style: TextStyle(color: AppColors.text)),
                  ),
                  const Expanded(child: Divider(thickness: 1)),
                ],
              ),

              /// Social Login
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialIconButton(
                    icon: Icons.g_mobiledata,
                    color: Colors.redAccent,
                    onTap: controller.googleLogin,
                  ),
                  const SizedBox(width: 16),
                  _socialIconButton(
                    icon: Icons.facebook,
                    color: Colors.blueAccent,
                    onTap: () {}, // Add FB login logic
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: AppColors.text,
        radius: 26,
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}
