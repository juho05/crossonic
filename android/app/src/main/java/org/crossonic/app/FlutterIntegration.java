package org.crossonic.app;

import android.content.Context;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import java.util.*;

public class FlutterIntegration {
    private static final String ENGINE_ID = "crossonic_flutter_engine";

    private static FlutterEngine flutterEngine;

    private static EventChannel.EventSink eventSink;

    private static final Map<String, List<MethodCallback>> methodCallbacks = new HashMap<>();

    public static void init(Context applicationContext) {
        flutterEngine = new FlutterEngine(applicationContext);
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine);
        flutterEngine.getDartExecutor().executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault());
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "org.crossonic.app.methods").setMethodCallHandler(FlutterIntegration::onMethodCall);
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "org.crossonic.app.events").setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
            }
            @Override
            public void onCancel(Object arguments) {
                eventSink = null;
            }
        });
    }

    public static FlutterEngine getEngine() {
        return flutterEngine;
    }

    public static void sendEvent(String event, Map<String, Object> data) {
        if (eventSink == null) return;
        final Map<String, Object> map = new HashMap<>();
        map.put("event", event);
        if (data != null) {
            map.put("data", data);
        }
        eventSink.success(map);
    }

    public static void sendError(String errorCode, String errorMessage, Object errorDetails) {
        if (eventSink == null) return;
        eventSink.error(errorCode, errorMessage, errorDetails);
    }

    public static void addMethodCallback(String methodName, MethodCallback callback) {
        final List<MethodCallback> list = methodCallbacks.computeIfAbsent(methodName, s -> new LinkedList<>());
        list.add(callback);
    }

    public static void removeMethodCallback(String methodName, MethodCallback callback) {
        final List<MethodCallback> list = methodCallbacks.get(methodName);
        if (list == null) return;
        list.remove(callback);
        if (list.isEmpty()) {
            methodCallbacks.remove(methodName);
        }
    }

    private static void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        final List<MethodCallback> callbacks = methodCallbacks.get(call.method);
        if (callbacks == null) return;
        for (MethodCallback callback : callbacks) {
            callback.onMethodCall(call, result);
        }
    }
}
