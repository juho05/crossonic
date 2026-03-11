package org.crossonic.app;

import android.app.Application;
import android.util.Log;

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
