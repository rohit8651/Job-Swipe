import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:parser/const/colors.dart';
import 'package:parser/modals/user.dart';

import '../../controller/login_controller.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final LoginController controller = Get.find<LoginController>();
  late TextEditingController nameController;
  late TextEditingController emailController;
  Rx<UserAccount> user = UserAccount().obs;
  RxString profileImagePath = ''.obs;

  @override
  void initState() {
    super.initState();
    controller.loadUser();
    user.value = controller.userAccount;
    profileImagePath = user.value.profilePicture.value.obs;
    nameController = TextEditingController(text: user.value.name.value);
    emailController = TextEditingController(text: user.value.email.value);
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.container,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.text),
                title: Text('Camera', style: TextStyle(color: AppColors.text)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                  );
                  if (picked != null) {
                    final url = await uploadToCloudinary(File(picked.path));
                    if (url != null) profileImagePath.value = url;
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.text),
                title: Text('Gallery', style: TextStyle(color: AppColors.text)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    final url = await uploadToCloudinary(File(picked.path));
                    if (url != null) profileImagePath.value = url;
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> uploadToCloudinary(File imageFile) async {
    const cloudName = 'YOUR-CLOUD-NAME';
    const uploadPreset = 'YOUR-CLOUD-PRESET';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

    final response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final data = json.decode(resStr);
      print("Image uploaded successfully: ${data['secure_url']}");
      return data['secure_url']; // Cloudinary image URL
    } else {
      print("Upload failed with status ${response.statusCode}");
      return null;
    }
  }

  void _submitChanges() {
    user.value.name.value = nameController.text;
    user.value.email.value = emailController.text;
    user.value.profilePicture.value = profileImagePath.value;
    controller.updateDoc(user.value);
    Get.snackbar(
      "Success",
      "Account updated successfully",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        title: Text('My Account', style: TextStyle(color: AppColors.text)),
        centerTitle: true,
      ),
      body: Obx(
        () => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.container,
                  ),
                  child: Text(
                    'Edit Your Profile',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 100,
                    backgroundImage: profileImagePath.value.isNotEmpty
                        ? NetworkImage(profileImagePath.value)
                        : AssetImage('assets/profile_placeholder.jpg'),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.scaffold,
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 28,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Your Name:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: nameController,
                style: TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: AppColors.text),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.buttonBackground),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Your Email:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                style: TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: AppColors.text),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.buttonBackground),
                  ),
                ),
              ),
              SizedBox(height: 50),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    //border
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(color: Colors.white, width: 1),
                    ),
                    backgroundColor: AppColors.buttonBackground,
                  ),
                  onPressed: _submitChanges,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Update Profile",
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
