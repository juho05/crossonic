package org.crossonic.app;

import androidx.annotation.OptIn;
import androidx.media3.common.Timeline;
import androidx.media3.common.util.UnstableApi;
import org.jspecify.annotations.NonNull;

import java.util.Objects;

public class CustomTimeline extends Timeline {
    private final Timeline originalTimeline;

    public CustomTimeline(Timeline originalTimeline) {
        this.originalTimeline = originalTimeline;
    }

    @Override
    public int getWindowCount() {
        return originalTimeline.getWindowCount();
    }

    @OptIn(markerClass = UnstableApi.class)
    @Override
    public @NonNull Window getWindow(int windowIndex, @NonNull Window window, long defaultPositionProjectionUs) {
        final Window w = originalTimeline.getWindow(windowIndex, window, defaultPositionProjectionUs);
        window.set(
                w.uid,
                w.mediaItem,
                w.manifest,
                w.presentationStartTimeMs,
                w.windowStartTimeMs,
                w.elapsedRealtimeEpochOffsetMs,
                true,
                w.isDynamic,
                w.liveConfiguration,
                w.defaultPositionUs,
                Objects.requireNonNull(window.mediaItem.mediaMetadata.durationMs)*1000,
                w.firstPeriodIndex,
                w.lastPeriodIndex,
                w.positionInFirstPeriodUs
        );
        return window;
    }

    @Override
    public int getPeriodCount() {
        return originalTimeline.getPeriodCount();
    }

    @Override
    public @NonNull Period getPeriod(int periodIndex, @NonNull Period period, boolean setIds) {
        return originalTimeline.getPeriod(periodIndex, period, setIds);
    }

    @Override
    public int getIndexOfPeriod(@NonNull Object uid) {
        return originalTimeline.getIndexOfPeriod(uid);
    }

    @Override
    public @NonNull Object getUidOfPeriod(int periodIndex) {
        return originalTimeline.getUidOfPeriod(periodIndex);
    }
}
