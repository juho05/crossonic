package org.crossonic.app;

import androidx.annotation.NonNull;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public interface MethodCallback {
    void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result);
}
