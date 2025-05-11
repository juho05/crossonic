package de.julianh.crossonic;

import androidx.annotation.NonNull;

import com.ryanheise.audioservice.AudioServiceActivity;

import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends AudioServiceActivity {
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new AudioPlayer(getApplicationContext(), flutterEngine.getDartExecutor());
    }
}
