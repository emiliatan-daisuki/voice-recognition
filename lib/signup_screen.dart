import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'login_screen.dart'; // 로그인 화면

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isEmailVerified = false;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _isPasswordValid() {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordError = null;
        _confirmPasswordError = "비밀번호가 일치하지 않습니다.";
      });
      return false;
    }
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });
    return true;
  }

  Future<void> _sendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        Fluttertoast.showToast(msg: "이메일 인증을 보내었습니다. 인증을 완료해주세요.");
        setState(() {
          _isEmailVerified = false;
        });
        _checkEmailVerification();
      } else {
        Fluttertoast.showToast(msg: "이미 인증된 이메일입니다.");
        setState(() {
          _isEmailVerified = true;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "이메일 인증 실패: $e");
    }
  }

  Future<void> _checkEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null) {
      Timer.periodic(Duration(seconds: 5), (timer) async {
        await user.reload();
        if (user.emailVerified) {
          timer.cancel();
          setState(() {
            _isEmailVerified = true;
          });
          Fluttertoast.showToast(msg: "이메일 인증이 완료되었습니다.");
        }
      });
    }
  }

  Future<void> _signUp(BuildContext context) async {
    if (_isPasswordValid() && _isEmailVerified) {
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user?.sendEmailVerification();

        Fluttertoast.showToast(msg: "회원가입 성공! 인증 이메일을 확인하세요.");
        Navigator.pop(context);
      } catch (e) {
        Fluttertoast.showToast(msg: "회원가입 실패: $e");
      }
    } else {
      Fluttertoast.showToast(msg: "이메일 인증이 완료되지 않았습니다.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "이메일"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "비밀번호",
                errorText: _passwordError,
              ),
              obscureText: true,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: "비밀번호 확인",
                errorText: _confirmPasswordError,
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendVerificationEmail,
              child: Text("이메일 인증 보내기"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isEmailVerified ? () => _signUp(context) : null,
              child: Text("회원가입"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEmailVerified ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
