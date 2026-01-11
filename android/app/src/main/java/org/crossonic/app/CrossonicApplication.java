package org.crossonic.app;

import android.app.Application;

public class CrossonicApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        FlutterIntegration.init(this);
    }
}
