/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package org.crossonic.app;

import android.content.ComponentName;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import androidx.annotation.NonNull;
import androidx.media3.session.MediaController;
import androidx.media3.session.SessionToken;
import com.google.common.util.concurrent.ListenableFuture;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String LOCAL_NETWORK_PERMISSION = "android.permission.ACCESS_LOCAL_NETWORK";
    private static final int LOCAL_NETWORK_PERMISSION_REQUEST_CODE = 4242;

    private ListenableFuture<MediaController> mediaControllerFuture;

    private MethodChannel.Result pendingLocalNetworkResult;

    @Override
    protected void onStart() {
        super.onStart();
        CLog.debug("MainActivity.onStart", "Connecting to playback service", null);
        SessionToken sessionToken = new SessionToken(this, new ComponentName(this, PlaybackService.class));
        mediaControllerFuture = new MediaController.Builder(this, sessionToken).buildAsync();

        FlutterIntegration.setMethodCallback("requestLocalNetworkPermission", (call, result) -> handleRequestLocalNetworkPermission(result));
    }

    @Override
    protected void onStop() {
        super.onStop();
        CLog.debug("MainActivity.onStop", "Releasing playback service", null);
        MediaController.releaseFuture(mediaControllerFuture);

        FlutterIntegration.removeMethodCallback("requestLocalNetworkPermission");
    }

    private void handleRequestLocalNetworkPermission(@NonNull MethodChannel.Result result) {
        // Before Android 17 (API 37) local network access is implicitly granted via the INTERNET permission.
        if (Build.VERSION.SDK_INT < 37 || checkSelfPermission(LOCAL_NETWORK_PERMISSION) == PackageManager.PERMISSION_GRANTED) {
            result.success(true);
            return;
        }

        if (pendingLocalNetworkResult != null) {
            pendingLocalNetworkResult.success(false);
        }
        pendingLocalNetworkResult = result;
        requestPermissions(new String[]{LOCAL_NETWORK_PERMISSION}, LOCAL_NETWORK_PERMISSION_REQUEST_CODE);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode != LOCAL_NETWORK_PERMISSION_REQUEST_CODE || pendingLocalNetworkResult == null) {
            return;
        }
        boolean granted = grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED;
        pendingLocalNetworkResult.success(granted);
        pendingLocalNetworkResult = null;
    }

    @Override
    public FlutterEngine provideFlutterEngine(@NonNull Context context) {
        CLog.trace("MainActivity", "provideFlutterEngine", null);
        return FlutterIntegration.getEngine(context);
    }
}
