package com.kms.findyourphone

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import android.content.Intent

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // BackgroundService 시작
        val serviceIntent = Intent(this, BackgroundService::class.java)
        startService(serviceIntent)
    }
}
