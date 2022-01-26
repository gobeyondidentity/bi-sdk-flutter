package com.beyondidentity.flutter.embeddedsdk_example

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("OnCreate", "Intent URI = ${intent.data}")
    }
}
