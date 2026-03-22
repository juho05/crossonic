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
import androidx.annotation.NonNull;
import androidx.media3.session.MediaController;
import androidx.media3.session.SessionToken;
import com.google.common.util.concurrent.ListenableFuture;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterActivity {
    private ListenableFuture<MediaController> mediaControllerFuture;

    @Override
    protected void onStart() {
        super.onStart();
        CLog.debug("MainActivity.onStart", "Connecting to playback service", null);
        SessionToken sessionToken = new SessionToken(this, new ComponentName(this, PlaybackService.class));
        mediaControllerFuture = new MediaController.Builder(this, sessionToken).buildAsync();
    }

    @Override
    protected void onStop() {
        super.onStop();
        CLog.debug("MainActivity.onStop", "Releasing playback service", null);
        MediaController.releaseFuture(mediaControllerFuture);
    }

    @Override
    public FlutterEngine provideFlutterEngine(@NonNull Context context) {
        CLog.trace("MainActivity", "provideFlutterEngine", null);
        return FlutterIntegration.getEngine(context);
    }
}
