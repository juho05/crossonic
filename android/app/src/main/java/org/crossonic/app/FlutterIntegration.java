package org.crossonic.app;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.concurrent.futures.CallbackToFutureAdapter;
import com.google.common.util.concurrent.ListenableFuture;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import java.util.*;
import java.util.concurrent.*;

public class FlutterIntegration {
    private static class MCall {
        MethodCall call;
        MethodChannel.Result result;
        MCall(MethodCall call, MethodChannel.Result result) {
            this.call = call;
            this.result = result;
        }
    }

    public static final String ENGINE_ID = "crossonic_flutter_engine";

    private static FlutterEngine flutterEngine = null;

    private static EventChannel.EventSink eventSink;
    private static MethodChannel methodChannel;

    private static final Map<String, MethodCallback> methodCallbacks = new HashMap<>();
    private static final Map<String, List<MCall>> unhandledCalls = new HashMap<>();

    public static FlutterEngine getEngine(Context context) {
        if (flutterEngine != null) {
            return flutterEngine;
        }
        flutterEngine = new FlutterEngine(context.getApplicationContext());
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine);
        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "org.crossonic.app.player.methods");
        methodChannel.setMethodCallHandler(FlutterIntegration::onMethodCall);
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "org.crossonic.app.player.events").setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
            }
            @Override
            public void onCancel(Object arguments) {
                eventSink = null;
            }
        });
        flutterEngine.getDartExecutor().executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault());
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

    private static final Handler mainThreadHandler = new Handler(Looper.getMainLooper());
    public static ListenableFuture<Object> invokeMethod(String method, @Nullable Object arguments) {
        return CallbackToFutureAdapter.getFuture(completer->{
            Log.e("ANDROIDAUTO", "invoke method");
            mainThreadHandler.post(()->{
                methodChannel.invokeMethod(method, arguments, new MethodChannel.Result() {
                    @Override
                    public void success(@Nullable @org.jspecify.annotations.Nullable Object result) {
                        Log.e("ANDROIDAUTO", "invoke method success");
                        completer.set(result);
                    }

                    @Override
                    public void error(@NonNull @org.jspecify.annotations.NonNull String errorCode, @Nullable @org.jspecify.annotations.Nullable String errorMessage, @Nullable @org.jspecify.annotations.Nullable Object errorDetails) {
                        Log.e("ANDROIDAUTO", "invoke method error");
                        completer.setException(new Exception(errorMessage));
                    }

                    @Override
                    public void notImplemented() {
                        Log.e("ANDROIDAUTO", "invoke method not implemented");
                        completer.setException(new Exception("method " + method + " not implemented"));
                    }
                });
            });
            return "async invoke method";
        });
    }

    public static void setMethodCallback(String methodName, MethodCallback callback) {
        methodCallbacks.put(methodName, callback);
        final var calls = unhandledCalls.get(methodName);
        if (calls != null) {
            unhandledCalls.remove(methodName);
            for (MCall c : calls) {
                callback.onMethodCall(c.call, c.result);
            }
        }
    }

    public static void removeMethodCallback(String methodName) {
        methodCallbacks.remove(methodName);
    }

    private static void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        final MethodCallback callback = methodCallbacks.get(call.method);
        if (callback == null) {
            unhandledCalls.putIfAbsent(call.method, new LinkedList<>());
            Objects.requireNonNull(unhandledCalls.get(call.method)).add(new MCall(call, result));
            return;
        }
        callback.onMethodCall(call, result);
    }
}
