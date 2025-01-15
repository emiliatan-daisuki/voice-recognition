import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

// 자동 로그인 처리 화면
class InitialScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _auth.currentUser != null ? Future.value(_auth.currentUser) : _auth.authStateChanges().first,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // 이미 로그인된 사용자라면 바로 이름 인식 앱 화면으로 이동
          return NameRecognitionApp();
        } else {
          // 로그인되지 않은 사용자라면 로그인 화면으로 이동
          return LoginScreen();
        }
      },
    );
  }
}

// 로그인 화면
class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login(BuildContext context) async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NameRecognitionApp()),
      );
    } catch (e) {
      print("로그인 실패: $e");
      Fluttertoast.showToast(msg: "로그인 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("로그인")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "이메일"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "비밀번호"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: Text("로그인"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
              child: Text("회원가입"),
            ),
          ],
        ),
      ),
    );
  }
}


// 회원가입 화면
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

  // 비밀번호 확인 함수
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

  // 이메일 인증 보내기
  Future<void> _sendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        Fluttertoast.showToast(msg: "이메일 인증을 보내었습니다. 인증을 완료해주세요.");
        setState(() {
          _isEmailVerified = false;  // 인증이 아직 완료되지 않았음
        });

        // 이메일 인증을 확인하는 타이머 시작
        _checkEmailVerification();
      } else {
        Fluttertoast.showToast(msg: "이미 인증된 이메일입니다.");
        setState(() {
          _isEmailVerified = true;  // 이미 인증이 완료된 경우
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "이메일 인증 실패: $e");
    }
  }

  // 이메일 인증 상태를 주기적으로 확인하는 함수
  Future<void> _checkEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // 일정 시간마다 이메일 인증 상태를 확인
      Timer.periodic(Duration(seconds: 5), (timer) async {
        await user.reload(); // 사용자 정보를 새로고침
        if (user.emailVerified) {
          timer.cancel();  // 인증이 완료되면 타이머 종료
          setState(() {
            _isEmailVerified = true; // 인증 완료
          });
          Fluttertoast.showToast(msg: "이메일 인증이 완료되었습니다.");
        }
      });
    }
  }

  // 회원가입 처리
  Future<void> _signUp(BuildContext context) async {
    if (_isPasswordValid() && _isEmailVerified) {
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        // Firebase에서 이메일과 비밀번호로 사용자 생성
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 인증 이메일 보내기
        await userCredential.user?.sendEmailVerification();

        // 인증 이메일을 보내었다는 메시지 출력
        Fluttertoast.showToast(msg: "회원가입 성공! 인증 이메일을 확인하세요.");

        // 회원가입 후 로그인 화면으로 돌아가기
        Navigator.pop(context);
      } catch (e) {
        print("회원가입 실패: $e");
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


// 이름 인식 앱
class NameRecognitionApp extends StatefulWidget {
  @override
  _NameRecognitionAppState createState() => _NameRecognitionAppState();
}

class _NameRecognitionAppState extends State<NameRecognitionApp> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isListening = false;
  String _recognizedText = "";
  String? _savedName;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeFirestore();
  }

  // 마이크 권한 요청
  Future<void> _requestPermissions() async {
    var status = await Permission.microphone.request();
    if (status.isDenied) {
      await _tts.speak("마이크 권한이 필요합니다.");
    }
    print("마이크 권한 상태: $status");
  }

  // Firestore에서 이름 가져오기
  Future<void> _initializeFirestore() async {
    try {
      DocumentSnapshot snapshot =
      await _firestore.collection('names').doc('user_name').get();
      if (snapshot.exists) {
        setState(() {
          _savedName = snapshot.get('name');
        });
        print("저장된 이름: $_savedName");
      }
    } catch (e) {
      print("Firestore 오류: $e");
      await _tts.speak("Firestore에 접근할 수 없습니다.");
    }
  }

  // 음성 인식 시작
  Future<void> _startListening() async {
    if (_isListening) {
      print("음성 인식 이미 진행 중입니다.");
      return;
    }

    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      print("음성 인식 시작");

      _speech.listen(onResult: (result) async {
        _recognizedText = result.recognizedWords;
        print("인식된 텍스트: $_recognizedText");

        // 이름 지정 명령어 처리
        if (_recognizedText.toLowerCase().startsWith("이름 지정")) {
          String newName = _recognizedText.substring(5).trim(); // '이름 지정' 이후의 텍스트 추출

          if (newName.isNotEmpty) {
            setState(() {
              _savedName = newName;
            });

            // Firestore에 새로운 이름 저장
            await _firestore.collection('names').doc('user_name').set({
              'name': _savedName,
            });

            await _tts.speak("이름이 $_savedName 로 저장되었습니다.");
            _speech.stop();
            setState(() => _isListening = false);
            print("이름 저장 완료: $_savedName");
          } else {
            await _tts.speak("이름을 정확히 말해주세요.");
            _speech.stop();
            setState(() => _isListening = false);
          }
        } else if (_recognizedText.toLowerCase() == _savedName?.toLowerCase()) {
          await _tts.speak("네, 부르셨나요?");
          print("이름 인식됨: $_savedName");
        }
      });
    } else {
      print("음성 인식 초기화 실패");
    }
  }

  // 음성 인식 중지
  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    print("음성 인식 중지됨");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("이름 인식 앱")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _savedName == null
                  ? "저장된 이름이 없습니다."
                  : "저장된 이름: $_savedName",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            // 음성 인식 상태 텍스트
            Text(
              _isListening
                  ? "음성 인식 중..."
                  : "음성 인식을 시작하려면 버튼을 눌러주세요.",
              style: TextStyle(
                fontSize: 16,
                color: _isListening ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 20),
            // 음성 인식 버튼과 마이크 아이콘 상태 표시
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_off,
                    color: _isListening ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 10),
                  Text(_isListening ? "듣기 중지" : "듣기 시작"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
