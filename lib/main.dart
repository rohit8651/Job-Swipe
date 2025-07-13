import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parser/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    if (kIsWeb) {
  await Firebase.initializeApp(
    options: FirebaseOptions(
    apiKey: 'AIzaSyB4PP1kBogxYwUU2ui5Pk-D9i1syOISz_o',
    appId: '1:251409487085:web:ea77c44d219ea28ae2e8e4',
    messagingSenderId: '251409487085',
    projectId: 'hodotrek',
    authDomain: 'hodotrek.firebaseapp.com',
    storageBucket: 'hodotrek.firebasestorage.app',
    measurementId: 'G-DV4WKRG5KN')
  );}
  else{
    await Firebase.initializeApp(
    options: FirebaseOptions(
    apiKey: 'AIzaSyAvtVRV-tMkMHRxMTZ0mQ9RnDLnLW5QKDg',
    appId: '1:251409487085:android:2448805881bd4324e2e8e4',
    messagingSenderId: '251409487085',
    projectId: 'hodotrek',
    storageBucket: 'hodotrek.firebasestorage.app'));
  }
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Resume Builder',
      //dark theme
      theme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
