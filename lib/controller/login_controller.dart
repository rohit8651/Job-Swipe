import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:parser/modals/user.dart';
import 'package:parser/view/nav/wrapper.dart';

import '../view/resume_parser_screen.dart';

class LoginController extends GetxController {
  final TextEditingController email = TextEditingController();
  final TextEditingController pass = TextEditingController();
  final TextEditingController name = TextEditingController();
  UserAccount userAccount = UserAccount();
  var emailText = ''.obs;
  var passText = ''.obs;
  var nameText = ''.obs;
  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  // LoginController() {
  //   loadUser();
  //   clearAll();
  // }

  @override
  void onInit() async {
    super.onInit();
    await loadUser();
    clearAll();
  }

  void clearAll() {
    email.clear();
    pass.clear();
    emailText.value = '';
    passText.value = '';
    isPasswordVisible.value = false;
    isLoading.value = false;
  }

  void clearEmail() {
    email.clear();
    emailText.value = '';
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
    print(isPasswordVisible.value);
  }

  Future<void> loadUser() async {
    User? currentUser = auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      if (snapshot.exists) {
        userAccount = UserAccount.fromJson(snapshot.data()!);
        print(userAccount.resumes.length);
      }
    }
  }

  Future<void> signIn() async {
    isLoading.value = true;
    try {
      await auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );

      String uid = auth.currentUser!.uid;

      userAccount = UserAccount(
        id: uid,
        name: name.text.trim(),
        email: email.text.trim(),
        profilePicture:
            "https://www.freepik.com/premium-vector/3d-vector-icon-simple-blue-user-profile-icon-with-white-features_404491443.htm#fromView=keyword&page=1&position=12&uuid=7cef09de-8ff2-43b3-8dbf-236edf28caf8&query=Default+User",
        password: pass.text.trim(),
        resumes: [],
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userAccount.toJson());

      Get.snackbar('Success', 'Signed in with Email');
      clearAll();
      Get.offAll(ResumeParserScreen(resume: Resume()));
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
    isLoading.value = false;
  }

  Future<void> login() async {
    isLoading.value = true;
    try {
      await auth.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );

      //get doc of that user
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(auth.currentUser!.uid)
              .get();
      userAccount = UserAccount.fromJson(snapshot.data()!);

      Get.snackbar('Success', 'Logged in with Email');
      clearAll();
      loadUser();
      Get.offAll(ResumeParserScreen(resume: Resume()));
    } catch (e) {
      Get.snackbar('Error', e.toString());
      clearAll();
    }
    isLoading.value = false;
  }

  Future<UserCredential?> googleLogin() async {
    isLoading.value = true;
    try {
      await googleSignIn.signOut();
      final GoogleSignInAccount? user = await googleSignIn.signIn();
      if (user == null) return null;

      final GoogleSignInAuthentication gAuth = await user.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // Get UID of the signed-in user
      final String uid = userCredential.user!.uid;

      //store user on firebase
      UserAccount newUser = UserAccount(
        id: uid,
        name: user.displayName,
        email: user.email,
        profilePicture: user.photoUrl,
        password: '******',
        resumes: [],
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(newUser.toJson());

      isLoading.value = false;
      Get.snackbar('Success', 'Logged in with Google');
      clearAll();
      loadUser();
      Get.offAll(MainNavigation());
      return await auth.signInWithCredential(credential);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
    isLoading.value = false;
    return null;
  }

  void signOut() async {
    await auth.signOut();
    await googleSignIn.signOut();
    clearAll();
    Get.snackbar('Success', 'Logged out');
  }

  Future<void> updateDoc(UserAccount user) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.id.value)
        .update(user.toJson());
    userAccount = user;
    loadUser();
    Get.snackbar(
      'Success',
      'Updated Successfully',
      backgroundColor: Colors.green,
    );
  }
}
