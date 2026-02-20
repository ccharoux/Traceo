package com.ccharoux.traceo

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import androidx.core.view.WindowCompat

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Indique à Android de laisser Flutter dessiner sous les barres système
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }
}
