package org.crossonic.app;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

public class CLog {
    private static CLogLevel level = CLogLevel.debug;
    private static boolean receivedFirstLogLevelMethodCall = false;

    private static final List<Map<String, Object>> unsentMessages = new LinkedList<>();

    public static void init() {
        FlutterIntegration.setMethodCallback("setLogLevel", (call, result) -> {
            onSetLogLevel((String)call.arguments);
            result.success(null);
        });
    }

    public static void trace(@NonNull String tag, @NonNull String message, @Nullable Throwable e) {
        log(CLogLevel.trace, tag, message, e);
    }

    public static void debug(@NonNull String tag, @NonNull String message, @Nullable Throwable e) {
        log(CLogLevel.debug, tag, message, e);
    }

    public static void info(@NonNull String tag, @NonNull String message, @Nullable Throwable e) {
        log(CLogLevel.info, tag, message, e);
    }

    public static void warn(@NonNull String tag, @NonNull String message, @Nullable Throwable e) {
        log(CLogLevel.warning, tag, message, e);
    }

    public static void error(@NonNull String tag, @NonNull String message, @Nullable Throwable e) {
        log(CLogLevel.error, tag, message, e);
    }

    public static void fatal(@NonNull String tag, @NonNull String message, @Nullable Throwable e) {
        log(CLogLevel.fatal, tag, message, e);
    }

    public static void log(@NonNull CLogLevel level, @NonNull String tag, @NonNull String message, @Nullable Throwable e) {
        if (level.compareTo(CLog.level) < 0) return;
        final Map<String, Object> data = new HashMap<>();
        data.put("level", level.name());
        data.put("message", message);
        data.put("tag", tag);
        data.put("time", System.currentTimeMillis());
        if (e != null) {
            String s = e.getClass().getName();
            String eMessage = e.getLocalizedMessage();
            data.put("exception", (eMessage != null) ? (s + ": " + eMessage) : s);

            StringWriter sw = new StringWriter();
            PrintWriter pw = new PrintWriter(sw);
            e.printStackTrace(pw);
            data.put("stackTrace", sw.toString());
        }
        if (!receivedFirstLogLevelMethodCall) {
            unsentMessages.add(data);
            return;
        }
        FlutterIntegration.sendEvent("log", data);
    }

    private static void onSetLogLevel(String logLevel) {
        level = CLogLevel.valueOf(logLevel);
        if (!receivedFirstLogLevelMethodCall) {
            receivedFirstLogLevelMethodCall = true;
            for (var data : unsentMessages) {
                FlutterIntegration.sendEvent("log", data);
            }
            unsentMessages.clear();
        }
    }
}
