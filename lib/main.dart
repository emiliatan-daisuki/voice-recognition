import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart'; // 로그인 화면
import 'signup_screen.dart'; // 회원가입 화면
import 'name_recognition_app.dart'; // 이름 인식 앱 화면

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyCZjMfBpvjfa485wYNc3xJ91vMHlm9E5Gk",
        authDomain: "findyourphone.kms.com",
        projectId: "findyourphone-aa9e9",
        storageBucket: "your_project_id.appspot.com",
        messagingSenderId: "your_messaging_sender_id",
        appId: "your_app_id",
        measurementId: "your_measurement_id",
      ),
    );
    print("Firebase Initialized");
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InitialScreen(),
    );
  }
}

class InitialScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: FirebaseAuth.instance.currentUser != null
          ? Future.value(FirebaseAuth.instance.currentUser)
          : FirebaseAuth.instance.authStateChanges().first,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return NameRecognitionApp();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}
