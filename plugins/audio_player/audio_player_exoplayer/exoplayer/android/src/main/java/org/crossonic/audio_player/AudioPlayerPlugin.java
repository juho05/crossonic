package org.crossonic.audio_player;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

public class AudioPlayerPlugin implements FlutterPlugin, ActivityAware {
    private static final String METHOD_CHANNEL = "org.crossonic.exoplayer.method";
    private static final String EVENT_CHANNEL = "org.crossonic.exoplayer.event";

    private boolean channelsInitialized = false;
    private MethodChannel methodChannel;
    private EventChannel eventChannel;

    private FlutterPluginBinding flutterPluginBinding;

    private AudioPlayer player;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        if (player == null) {
            player = AudioPlayer.getInstance(binding.getApplicationContext());
        }
        flutterPluginBinding = binding;
        if (!channelsInitialized) {
            initPlugin(flutterPluginBinding.getBinaryMessenger());
        }
    }

    private void initPlugin(BinaryMessenger binaryMessenger) {
        methodChannel = new MethodChannel(binaryMessenger, METHOD_CHANNEL);
        methodChannel.setMethodCallHandler(player::onMethodCall);
        eventChannel = new EventChannel(binaryMessenger, EVENT_CHANNEL);
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                player.updateEventSink(events);
            }

            @Override
            public void onCancel(Object arguments) {
            }
        });
        channelsInitialized = true;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {}

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        if (flutterPluginBinding == null) return;
        initPlugin(flutterPluginBinding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromActivity() {
        if (!channelsInitialized) return;
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;
        eventChannel.setStreamHandler(null);
        eventChannel = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {}

    @Override
    public void onDetachedFromActivityForConfigChanges() {}
}