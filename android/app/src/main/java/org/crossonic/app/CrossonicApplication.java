/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package org.crossonic.app;

import android.app.Application;

public class CrossonicApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        CLog.init();
        final Thread.UncaughtExceptionHandler defaultUncaughtExceptionHandler = Thread.getDefaultUncaughtExceptionHandler();
        if (defaultUncaughtExceptionHandler != null) {
            Thread.setDefaultUncaughtExceptionHandler((t, e) -> {
                try {
                    CLog.fatal("CrossonicApplication", "An uncaught exception occurred", e);
                } finally {
                    defaultUncaughtExceptionHandler.uncaughtException(t, e);
                }
            });
        } else {
            CLog.warn("CrossonicApplication.onCreate", "No default uncaught exception handler available, skip custom wrapping handler for logging to avoid issues", null);
        }
        FlutterIntegration.getEngine(this);
    }
}
