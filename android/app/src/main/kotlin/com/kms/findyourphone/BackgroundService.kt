package com.kms.findyourphone

import android.app.Service
import android.content.Intent
import android.os.Bundle
import android.os.IBinder
import android.speech.SpeechRecognizer
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.widget.Toast

class BackgroundService : Service() {

    private lateinit var speechRecognizer: SpeechRecognizer

    override fun onCreate() {
        super.onCreate()

        // SpeechRecognizer 초기화
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                // 준비 완료 시 호출
            }

            override fun onBeginningOfSpeech() {
                // 말하기 시작 시 호출
            }

            override fun onRmsChanged(rmsdB: Float) {
                // 소음 레벨 변경 시 호출
            }

            override fun onBufferReceived(buffer: ByteArray?) {
                // 음성 데이터 받기
            }

            override fun onEndOfSpeech() {
                // 말하기 끝날 때 호출
            }

            override fun onError(error: Int) {
                // 오류 발생 시 호출
                Toast.makeText(applicationContext, "음성 인식 오류: $error", Toast.LENGTH_SHORT).show()
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (matches != null && matches.isNotEmpty()) {
                    // 음성 인식 결과 처리
                    val recognizedText = matches[0]
                    // 여기에서 recognizedText로 필요한 작업을 진행
                    Toast.makeText(applicationContext, "인식된 텍스트: $recognizedText", Toast.LENGTH_SHORT).show()
                }
            }

            override fun onPartialResults(partialResults: Bundle?) {
                // 부분 결과 처리
            }

            override fun onEvent(eventType: Int, params: Bundle?) {
                // 이벤트 처리
            }
        })
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        // 음성 인식 시작
        val recognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
        recognizerIntent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        recognizerIntent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, "ko-KR") // 한국어로 설정
        speechRecognizer.startListening(recognizerIntent)
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        // 서비스 종료 시 리소스 해제
        speechRecognizer.stopListening()
        speechRecognizer.destroy()
    }
}
