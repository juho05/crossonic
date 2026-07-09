/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package org.crossonic.app;

import android.content.Context;
import android.os.Handler;
import android.os.PowerManager;

import androidx.annotation.NonNull;
import androidx.media3.common.C;
import androidx.media3.common.MediaItem;
import androidx.media3.common.SimpleBasePlayer;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.common.util.Util;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@UnstableApi
public class FlutterPlayer extends SimpleBasePlayer {
    private MediaItemData currentMediaItem = null;
    private int playbackState = STATE_IDLE;
    private boolean playing = false;
    private boolean loading = false;
    private PositionSupplier position = PositionSupplier.ZERO;

    private boolean active = false;
    private final PowerManager.WakeLock wakeLock;

    private static final long WAKE_LOCK_TIMEOUT_MS = 90_000L;
    private final Handler handler;
    private final Runnable wakeLockTimeout = this::onWakeLockTimeout;

    public FlutterPlayer(@NonNull Context context) {
        super(Util.getCurrentOrMainLooper());
        handler = new Handler(Util.getCurrentOrMainLooper());
        final Context appContext = context.getApplicationContext();

        final PowerManager powerManager = (PowerManager) appContext.getSystemService(Context.POWER_SERVICE);
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "crossonic:cast-playback");
        wakeLock.setReferenceCounted(false);

        registerMethodHandlers();
    }

    public void setActive(boolean active) {
        this.active = active;
        updateWakeLock();
    }

    private void updateWakeLock() {
        final boolean shouldHold = active && (playing || loading);
        CLog.debug("FlutterPlayer", "updateWakeLock: active=" + active + ", playing=" + playing + ", loading=" + loading + " -> hold=" + shouldHold, null);
        if (shouldHold) {
            if (!wakeLock.isHeld()) {
                wakeLock.acquire();
            }
            armWakeLockTimeout();
        } else {
            handler.removeCallbacks(wakeLockTimeout);
            releaseWakeLock();
        }
    }

    private void releaseWakeLock() {
        if (wakeLock.isHeld()) {
            wakeLock.release();
        }
    }

    private void armWakeLockTimeout() {
        handler.removeCallbacks(wakeLockTimeout);
        handler.postDelayed(wakeLockTimeout, WAKE_LOCK_TIMEOUT_MS);
    }

    private void onWakeLockTimeout() {
        CLog.warn("FlutterPlayer", "wake lock backstop fired (no position updates in " + WAKE_LOCK_TIMEOUT_MS + "ms); force-releasing lock", null);
        releaseWakeLock();
    }

    private void refreshWakeLockTimeout() {
        if (wakeLock.isHeld()) {
            armWakeLockTimeout();
        }
    }

    private void registerMethodHandlers() {
        FlutterIntegration.setMethodCallback("updatePosition", this::handleUpdatePosition);
        FlutterIntegration.setMethodCallback("updateMedia", this::handleUpdateMedia);
        FlutterIntegration.setMethodCallback("updatePlaybackState", this::handleUpdatePlaybackState);
    }

    private void unregisterMethodHandlers() {
        FlutterIntegration.removeMethodCallback("updatePosition");
        FlutterIntegration.removeMethodCallback("updateMedia");
        FlutterIntegration.removeMethodCallback("updatePlaybackState");
    }

    private void handleUpdatePosition(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        final long pos = ((Number) Objects.requireNonNull(call.argument("pos"))).longValue();
        if (playing) {
            position = PositionSupplier.getExtrapolating(pos, 1);
            refreshWakeLockTimeout();
        } else {
            position = PositionSupplier.getConstant(pos);
        }
        invalidateState();
        result.success(null);
    }

    private void handleUpdatePlaybackState(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        final String status = Objects.requireNonNull(call.argument("status"));
        CLog.debug("FlutterPlayer", "new status: " + status, null);
        switch (status) {
            case "stopped":
                playing = false;
                loading = false;
                playbackState = STATE_IDLE;
                position = PositionSupplier.ZERO;
                break;
            case "loading":
                playing = false;
                loading = true;
                playbackState = STATE_BUFFERING;
                position = PositionSupplier.getConstant(position.get());
                break;
            case "paused":
                playing = false;
                loading = false;
                playbackState = STATE_READY;
                position = PositionSupplier.getConstant(position.get());
                break;
            case "playing":
                playing = true;
                loading = false;
                playbackState = STATE_READY;
                position = PositionSupplier.getExtrapolating(position.get(), 1);
                break;
        }
        updateWakeLock();
        invalidateState();
        result.success(null);
    }

    private void handleUpdateMedia(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        final Map<Object, Object> media = call.argument("media");

        if (media == null) {
            currentMediaItem = null;
            invalidateState();
            result.success(null);
            return;
        }

        final var mediaBuilder = new MediaItem.Builder();
        Mappings.buildMediaItemFromMsg(mediaBuilder, media);
        final var mediaItem = mediaBuilder.build();

        final var mediaItemDataBuilder = new MediaItemData.Builder(mediaItem.mediaId);
        if (mediaItem.mediaMetadata.durationMs != null) {
            mediaItemDataBuilder.setDurationUs(mediaItem.mediaMetadata.durationMs * 1000);
        }
        mediaItemDataBuilder.setIsSeekable(true);
        mediaItemDataBuilder.setMediaItem(mediaItem);
        mediaItemDataBuilder.setMediaMetadata(mediaItem.mediaMetadata);

        currentMediaItem = mediaItemDataBuilder.build();

        CLog.debug("FlutterPlayer", "new media: " + currentMediaItem.uid, null);

        invalidateState();
        result.success(null);
    }

    @NonNull
    @Override
    protected State getState() {
        final List<MediaItemData> playlist = new ArrayList<>();
        if (currentMediaItem != null) {
            playlist.add(currentMediaItem);
        }
        CLog.debug("FlutterPlayer", "getState: called: state: " + playbackState + ", currentMediaItem: " + currentMediaItem, null);

        final int state = playlist.isEmpty() ? STATE_IDLE : playbackState;

        return new SimpleBasePlayer.State.Builder().setAvailableCommands(availableCommands).setContentPositionMs(position)
                .setIsLoading(loading && state != STATE_ENDED && state != STATE_IDLE).setPlaybackState(state)
                .setPlaylist(playlist)
                .setPlayWhenReady(playing, PLAY_WHEN_READY_CHANGE_REASON_USER_REQUEST).build();
    }

    @NonNull
    @Override
    protected ListenableFuture<?> handleSetPlayWhenReady(boolean playWhenReady) {
        if (playWhenReady) {
            FlutterIntegration.sendEvent("play", null);
        } else {
            FlutterIntegration.sendEvent("pause", null);
        }
        return Futures.immediateVoidFuture();
    }

    @NonNull
    @Override
    protected ListenableFuture<?> handleSeek(int mediaItemIndex, long positionMs, int seekCommand) {
        if (positionMs == C.TIME_UNSET) {
            positionMs = 0;
        }
        if (playing) {
            position = PositionSupplier.getExtrapolating(positionMs, 1);
        } else {
            position = PositionSupplier.getConstant(positionMs);
        }
        FlutterIntegration.sendEvent("seek", Map.of("pos", positionMs));
        return Futures.immediateVoidFuture();
    }

    @NonNull
    @Override
    protected ListenableFuture<?> handleStop() {
        // TODO: re-enable after stop on player change is fixed
        //FlutterIntegration.sendEvent("stop", null);
        return Futures.immediateVoidFuture();
    }

    @NonNull
    @Override
    protected ListenableFuture<?> handleRelease() {
        active = false;
        playing = false;
        loading = false;
        updateWakeLock();
        unregisterMethodHandlers();
        return Futures.immediateVoidFuture();
    }

    private static final Commands availableCommands = new Commands.Builder().addAll(
            COMMAND_PLAY_PAUSE,
            COMMAND_STOP,
            COMMAND_RELEASE,
            COMMAND_SEEK_TO_DEFAULT_POSITION,
            COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM,
            COMMAND_GET_CURRENT_MEDIA_ITEM,
            COMMAND_GET_METADATA,
            COMMAND_GET_TIMELINE
    ).build();
}
