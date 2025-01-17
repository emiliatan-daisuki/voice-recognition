import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

class NameRecognitionApp extends StatefulWidget {
  @override
  _NameRecognitionAppState createState() => _NameRecognitionAppState();
}

class _NameRecognitionAppState extends State<NameRecognitionApp> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isListening = false;
  String _recognizedText = "";
  String? _savedName;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initializeFirestore();
    _startListening(); // 앱 초기화 시 음성 인식 시작
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.microphone.request();
    if (status.isDenied) {
      await _tts.speak("마이크 권한이 필요합니다.");
    }
    print("마이크 권한 상태: $status");
  }

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

        if (_recognizedText.toLowerCase().startsWith("이름 지정")) {
          String newName = _recognizedText.substring(5).trim();

          if (newName.isNotEmpty) {
            setState(() {
              _savedName = newName;
            });

            await _firestore.collection('names').doc('user_name').set({
              'name': _savedName,
            });

            await _tts.speak("이름이 $_savedName 로 저장되었습니다.");
            print("이름 저장 완료: $_savedName");
          } else {
            await _tts.speak("이름을 정확히 말해주세요.");
          }
        } else if (_savedName != null &&
            _recognizedText.toLowerCase().trim() == _savedName!.toLowerCase().trim()) {
          await _tts.speak("소리를 재생합니다.");
          print("이름 인식됨: $_savedName");

          _playMusic();
        }

        // 음성 인식이 끝난 후 다시 인식을 시작하도록 호출
        _startListening();  // 여기를 추가해서 음성 인식이 지속적으로 되게 만듦
      });
    } else {
      print("음성 인식 초기화 실패");
    }
  }

  Future<void> _playMusic() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/music.mp3'));
      print("음악이 재생되고 있습니다.");
    } catch (e) {
      print("음악 재생 실패: $e");
    }
  }

  Future<void> _stopMusic() async {
    try {
      await _audioPlayer.stop();
      print("음악이 정지되었습니다.");
    } catch (e) {
      print("음악 정지 실패: $e");
    }
  }

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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _stopMusic,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stop, color: Colors.white),
                  SizedBox(width: 10),
                  Text("소리 종료"),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
