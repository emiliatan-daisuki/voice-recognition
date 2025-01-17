import UIKit
import Flutter
import Speech
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    var speechRecognizer: SFSpeechRecognizer?
    var audioEngine: AVAudioEngine?
    var audioSession: AVAudioSession?
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        super.application(application, didFinishLaunchingWithOptions: launchOptions)

        // Flutter Method Channel 설정
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let speechChannel = FlutterMethodChannel(name: "com.example.your_app/background",
                                                binaryMessenger: controller.binaryMessenger)

        speechChannel.setMethodCallHandler { [weak self] (call, result) in
            if call.method == "startBackgroundService" {
                self?.startBackgroundService()
                result("Background Service Started")
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        return true
    }

    func startBackgroundService() {
        // 음성 인식 및 TTS 작업을 시작하는 메서드 호출
        requestSpeechPermission()
    }

    func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            switch authStatus {
            case .authorized:
                self.startListening()
            case .denied, .restricted, .notDetermined:
                print("음성 인식 권한이 없습니다.")
            default:
                break
            }
        }
    }

    func startListening() {
        // 음성 인식 시작 설정 코드
        audioSession = AVAudioSession.sharedInstance()
        try? audioSession?.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? audioSession?.setActive(true, options: .notifyOthersOnDeactivation)

        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        audioEngine = AVAudioEngine()

        let inputNode = audioEngine?.inputNode
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: inputNode?.inputFormat(forBus: 0)) { (buffer, time) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine?.prepare()
        try? audioEngine?.start()

        // 음성 인식 시작
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { (result, error) in
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString
                print("인식된 텍스트: \(recognizedText)")
            }
        }
    }
}
