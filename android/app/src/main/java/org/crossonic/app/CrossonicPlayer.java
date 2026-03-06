package org.crossonic.app;

import android.content.Context;
import android.net.Uri;
import android.os.Looper;
import android.util.Log;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.TextureView;
import androidx.annotation.Nullable;
import androidx.annotation.OptIn;
import androidx.media3.common.*;
import androidx.media3.common.text.Cue;
import androidx.media3.common.text.CueGroup;
import androidx.media3.common.util.Size;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.Renderer;
import androidx.media3.exoplayer.RenderersFactory;
import androidx.media3.exoplayer.audio.MediaCodecAudioRenderer;
import androidx.media3.exoplayer.mediacodec.MediaCodecSelector;
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory;
import androidx.media3.exoplayer.util.EventLogger;
import androidx.media3.extractor.DefaultExtractorsFactory;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import org.jspecify.annotations.NonNull;

import java.io.*;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.util.*;

import static androidx.media3.common.MediaMetadata.PICTURE_TYPE_FRONT_COVER;

@OptIn(markerClass = UnstableApi.class)
public class CrossonicPlayer implements Player {
    private final Player player;

    private long positionOffsetMs = 0;

    private boolean supportsTimeOffset = true;
    private boolean supportsTimeOffsetMs = false;
    private boolean treatStopAsPause = false;

    private boolean loop = false;

    private final Set<Listener> listeners = new HashSet<>();

    public CrossonicPlayer(Context context) {
        player = buildPlayer(context);
        player.addListener(new PlayerListener());
        registerMethodHandlers();
        FlutterIntegration.sendEvent("playerCreated", null);
    }

    private Player buildPlayer(Context context) {
        // only enable audio renderers to allow unused renderers to be removed by code shrinking
        RenderersFactory audioOnlyRenderersFactory =
                (handler, videoListener, audioListener, textOutput, metadataOutput) ->
                        new Renderer[]{
                                new MediaCodecAudioRenderer(context, MediaCodecSelector.DEFAULT, handler, audioListener)
                        };
        final ExoPlayer.Builder builder = new ExoPlayer.Builder(context, audioOnlyRenderersFactory);
        builder.setMediaSourceFactory(new DefaultMediaSourceFactory(context, new DefaultExtractorsFactory().setConstantBitrateSeekingEnabled(true)));
        builder.setAudioAttributes(new AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).setAllowedCapturePolicy(C.ALLOW_CAPTURE_BY_ALL).build(), true);
        builder.setHandleAudioBecomingNoisy(true);

        final ExoPlayer player = builder.build();
        player.addAnalyticsListener(new EventLogger());

        player.setPlayWhenReady(false);
        player.setTrackSelectionParameters(
                player.getTrackSelectionParameters().buildUpon().
                        setAudioOffloadPreferences(new TrackSelectionParameters.AudioOffloadPreferences.Builder()
                                // enabling this causes transition bugs and infinite loading when transcoding is enabled
                                .setAudioOffloadMode(TrackSelectionParameters.AudioOffloadPreferences.AUDIO_OFFLOAD_MODE_DISABLED)
                                .setIsGaplessSupportRequired(true)
                                .build())
                        // disable all track types except for audio and default/unknown tracks
                        .setTrackTypeDisabled(C.TRACK_TYPE_VIDEO, true)
                        .setTrackTypeDisabled(C.TRACK_TYPE_IMAGE, true)
                        .setTrackTypeDisabled(C.TRACK_TYPE_CAMERA_MOTION, true)
                        .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                        .setTrackTypeDisabled(C.TRACK_TYPE_METADATA, true)
                        .build()
        );

        return player;
    }

    // ====== method channel handlers ======

    private void registerMethodHandlers() {
        FlutterIntegration.setMethodCallback("configure", this::handleConfigure);
        FlutterIntegration.setMethodCallback("setLoop", this::handleSetLoop);
        FlutterIntegration.setMethodCallback("play", this::handlePlay);
        FlutterIntegration.setMethodCallback("pause", this::handlePause);
        FlutterIntegration.setMethodCallback("setCurrent", this::handleSetCurrent);
        FlutterIntegration.setMethodCallback("setNext", this::handleSetNext);
        FlutterIntegration.setMethodCallback("updateCover", this::handleUpdateCover);
        FlutterIntegration.setMethodCallback("getPosition", this::handleGetPosition);
        FlutterIntegration.setMethodCallback("getBufferedPosition", this::handleGetBufferedPosition);
        FlutterIntegration.setMethodCallback("getVolume", this::handleGetVolume);
        FlutterIntegration.setMethodCallback("setVolume", this::handleSetVolume);
        FlutterIntegration.setMethodCallback("seek", this::handleSeek);
        FlutterIntegration.setMethodCallback("stop", this::handleStop);
        FlutterIntegration.setMethodCallback("dispose", this::handleDispose);
    }

    private void unregisterMethodHandlers() {
        FlutterIntegration.removeMethodCallback("configure");
        FlutterIntegration.removeMethodCallback("play");
        FlutterIntegration.removeMethodCallback("pause");
        FlutterIntegration.removeMethodCallback("setCurrent");
        FlutterIntegration.removeMethodCallback("setNext");
        FlutterIntegration.removeMethodCallback("updateCover");
        FlutterIntegration.removeMethodCallback("getPosition");
        FlutterIntegration.removeMethodCallback("getBufferedPosition");
        FlutterIntegration.removeMethodCallback("getVolume");
        FlutterIntegration.removeMethodCallback("setVolume");
        FlutterIntegration.removeMethodCallback("seek");
        FlutterIntegration.removeMethodCallback("stop");
        FlutterIntegration.removeMethodCallback("dispose");
    }

    private void handleConfigure(MethodCall call, MethodChannel.Result result) {
        if (call.hasArgument("supportsTimeOffset")) {
            supportsTimeOffset = Boolean.TRUE.equals(call.argument("supportsTimeOffset"));
        }
        if (call.hasArgument("supportsTimeOffsetMs")) {
            supportsTimeOffsetMs = Boolean.TRUE.equals(call.argument("supportsTimeOffsetMs"));
        }
        if (call.hasArgument("treatStopAsPause")) {
            treatStopAsPause = Boolean.TRUE.equals(call.argument("treatStopAsPause"));
        }
        result.success(null);
    }

    private void handleSetLoop(MethodCall call, MethodChannel.Result result) {
        // TODO flutter currently never calls this method
        loop = Boolean.TRUE.equals(call.argument("loop"));
        result.success(null);
    }

    private void handlePlay(MethodCall call, MethodChannel.Result result) {
        play();
        result.success(null);
    }

    private void handlePause(MethodCall call, MethodChannel.Result result) {
        pause();
        result.success(null);
    }

    private void handleSetCurrent(MethodCall call, MethodChannel.Result result) {
        final Map<Object, Object> current = call.argument("current");
        assert current != null;

        long pos = 0;
        if (call.hasArgument("pos")) {
            //noinspection DataFlowIssue
            pos = ((Number)call.argument("pos")).longValue();
        }

        Uri streamUri = Uri.parse((String)current.get("uri"));

        final var currentBuilder = new MediaItem.Builder();
        Mappings.buildMediaItemFromMsg(currentBuilder, current);
        if (pos > 0 && !canSeek(streamUri)) {
            streamUri = setUriTimeOffset(streamUri, pos);
        }
        currentBuilder.setUri(streamUri);
        final var currentMediaItem = currentBuilder.build();

        player.setMediaItem(currentMediaItem, canSeek(streamUri) ? pos : C.TIME_UNSET);
        positionOffsetMs = !canSeek(streamUri) ? pos : 0;

        if (player.getPlaybackState() == STATE_IDLE) {
            player.prepare();
        }

        final Map<Object, Object> next = call.argument("next");
        if (next == null) {
            result.success(null);
            return;
        }

        final var nextBuilder = new MediaItem.Builder();
        Mappings.buildMediaItemFromMsg(nextBuilder, next);
        final var nextMediaItem = nextBuilder.build();
        player.addMediaItem(nextMediaItem);
        result.success(null);
    }

    private void handleSetNext(MethodCall call, MethodChannel.Result result) {
        final Map<Object, Object> next = call.argument("next");
        if (next == null) {
            player.removeMediaItems(player.getCurrentMediaItemIndex()+1, Integer.MAX_VALUE);
            result.success(null);
            return;
        }

        final var nextBuilder = new MediaItem.Builder();
        Mappings.buildMediaItemFromMsg(nextBuilder, next);
        player.replaceMediaItems(player.getCurrentMediaItemIndex()+1, Integer.MAX_VALUE, Collections.singletonList(nextBuilder.build()));
        result.success(null);
    }

    private void handleUpdateCover(MethodCall call, MethodChannel.Result result) {
        final String songId = call.argument("songId");
        final byte[] coverBytes = call.argument("coverBytes");

        final var currentIndex = player.getCurrentMediaItemIndex();
        final var currentMediaItem = player.getCurrentMediaItem();

        final var nextIndex = player.getNextMediaItemIndex();
        final var nextMediaItem = player.hasNextMediaItem() ? player.getMediaItemAt(nextIndex) : null;

        if (currentMediaItem != null && currentMediaItem.mediaId.equals(songId)) {
            player.replaceMediaItem(currentIndex, currentMediaItem.buildUpon().
                    setMediaMetadata(currentMediaItem.mediaMetadata.buildUpon().setArtworkData(coverBytes, PICTURE_TYPE_FRONT_COVER).build()).build());
        }
        if (nextMediaItem != null && nextMediaItem.mediaId.equals(songId)) {
            player.replaceMediaItem(nextIndex, nextMediaItem.buildUpon().
                    setMediaMetadata(nextMediaItem.mediaMetadata.buildUpon().setArtworkData(coverBytes, PICTURE_TYPE_FRONT_COVER).build()).build());
        }

        result.success(null);
    }

    private void handleGetPosition(MethodCall call, MethodChannel.Result result) {
        final long pos = player.getCurrentPosition() + positionOffsetMs;
        result.success(pos);
    }

    private void handleGetBufferedPosition(MethodCall call, MethodChannel.Result result) {
        final long bufferedPos = player.getBufferedPosition() + positionOffsetMs;
        result.success(bufferedPos);
    }

    private void handleGetVolume(MethodCall call, MethodChannel.Result result) {
        final float volume = player.getVolume();
        result.success((double)volume);
    }

    private void handleSetVolume(MethodCall call, MethodChannel.Result result) {
        //noinspection DataFlowIssue
        final double volume = call.argument("volume");
        player.setVolume(Math.min(1, Math.max(0, (float)volume)));
        result.success(null);
    }

    private void handleSeek(MethodCall call, MethodChannel.Result result) {
        //noinspection DataFlowIssue
        final long pos = ((Number)call.argument("pos")).longValue();
        seekTo(pos);
        result.success(null);
    }

    private void handleStop(MethodCall call, MethodChannel.Result result) {
        player.clearMediaItems();
        player.stop();
        result.success(null);
    }

    private void handleDispose(MethodCall call, MethodChannel.Result result) {
        release();
        result.success(null);
    }

    private boolean canSeek(Uri uri) {
        if (!supportsTimeOffset && !supportsTimeOffsetMs) {
            // there is no alternative to seeking
            return true;
        }
        if (Objects.requireNonNull(uri.getScheme()).equalsIgnoreCase("file")) {
            return true;
        }
        if (Objects.equals(uri.getQueryParameter("format"), "raw")) {
            return true;
        }
        return false;
    }

    private Uri setUriTimeOffset(Uri uri, long offsetMs) {
        if (uri.getEncodedQuery() == null) return uri;
        final var queryParams = parseQuery(uri.getEncodedQuery());
        queryParams.remove("timeOffset");
        queryParams.remove("timeOffsetMs");
        if (supportsTimeOffsetMs) {
            queryParams.put("timeOffsetMs", Collections.singletonList(Long.toString(offsetMs)));
        } else {
            queryParams.put("timeOffset", Collections.singletonList(Long.toString(Math.round(offsetMs/1000.0))));
        }

        final var uriBuilder = uri.buildUpon();
        uriBuilder.encodedQuery(mapToQuery(queryParams));
        return uriBuilder.build();
    }

    private Map<String, List<String>> parseQuery(String query) {
        Map<String, List<String>> result = new LinkedHashMap<>();
        String[] pairs = query.split("&");
        for (String pair : pairs) {
            try {
                int idx = pair.indexOf("=");
                String key = idx > 0 ? URLDecoder.decode(pair.substring(0, idx), "UTF-8") : pair;
                String value = idx > 0 && pair.length() > idx + 1 ? URLDecoder.decode(pair.substring(idx + 1), "UTF-8") : null;
                result.putIfAbsent(key, new ArrayList<>());
                if (value != null) {
                    Objects.requireNonNull(result.get(key)).add(value);
                }
            } catch (UnsupportedEncodingException e) {
                throw new RuntimeException(e);
            }
        }
        return result;
    }

    private String mapToQuery(Map<String, List<String>> map) {
        StringBuilder sb = new StringBuilder();
        for (String key : map.keySet()) {
            if (sb.length() > 0) {
                sb.append("&");
            }
            for (String value : Objects.requireNonNull(map.get(key))) {
                try {
                    sb.append(URLEncoder.encode(key, "UTF-8")).append("=").append(URLEncoder.encode(value, "UTF-8"));
                } catch (UnsupportedEncodingException e) {
                    throw new RuntimeException(e);
                }
            }
        }
        return sb.toString();
    }


    // ====== player interface =======

    // changed

    @Override
    public long getCurrentPosition() {
        return player.getCurrentPosition() + positionOffsetMs;
    }

    @Override
    public long getBufferedPosition() {
        return player.getBufferedPosition() +  positionOffsetMs;
    }

    // unchanged

    @Override
    public @NonNull Looper getApplicationLooper() {
        return player.getApplicationLooper();
    }

    @Override
    public void addListener(@NonNull Listener listener) {
        listeners.add(listener);
    }

    @Override
    public void removeListener(@NonNull Listener listener) {
        listeners.remove(listener);
    }

    @Override
    public void setMediaItems(@NonNull List<MediaItem> mediaItems) {
        if (mediaItems.isEmpty()) return;

        // TODO properly implement this method
        setMediaItem(mediaItems.get(0));
    }

    @Override
    public void setMediaItems(@NonNull List<MediaItem> mediaItems, boolean resetPosition) {
        setMediaItems(mediaItems);
    }

    @Override
    public void setMediaItems(@NonNull List<MediaItem> mediaItems, int startIndex, long startPositionMs) {
        // TODO properly implement this method
        setMediaItem(mediaItems.get(startIndex), startPositionMs);
    }

    @Override
    public void setMediaItem(@NonNull MediaItem mediaItem) {
        setMediaItem(mediaItem, C.TIME_UNSET);
    }

    @Override
    public void setMediaItem(@NonNull MediaItem mediaItem, long startPositionMs) {
        final Map<String, Object> args = new HashMap<>();
        // TODO handle play from search requests
        args.put("id", mediaItem.mediaId);
        if (startPositionMs != C.TIME_UNSET) {
            args.put("startPositionMs", startPositionMs);
        }
        FlutterIntegration.invokeMethod("setMediaItem", args);
    }

    @Override
    public void setMediaItem(@NonNull MediaItem mediaItem, boolean resetPosition) {
        setMediaItem(mediaItem);
    }

    @Override
    public void addMediaItem(@NonNull MediaItem mediaItem) {}

    @Override
    public void addMediaItem(int index, @NonNull MediaItem mediaItem) {}

    @Override
    public void addMediaItems(@NonNull List<MediaItem> mediaItems) {}

    @Override
    public void addMediaItems(int index, @NonNull List<MediaItem> mediaItems) {}

    @Override
    public void moveMediaItem(int currentIndex, int newIndex) {}

    @Override
    public void moveMediaItems(int fromIndex, int toIndex, int newIndex) {}

    @Override
    public void replaceMediaItem(int index, @NonNull MediaItem mediaItem) {}

    @Override
    public void replaceMediaItems(int fromIndex, int toIndex, @NonNull List<MediaItem> mediaItems) {}

    @Override
    public void removeMediaItem(int index) {}

    @Override
    public void removeMediaItems(int fromIndex, int toIndex) {}

    @Override
    public void clearMediaItems() {}

    @Override
    public boolean isCommandAvailable(int command) {
        return availableCommands.contains(command);
    }

    @Override
    public boolean canAdvertiseSession() {
        return player.canAdvertiseSession();
    }

    @Override
    public @NonNull Commands getAvailableCommands() {
        return availableCommands;
    }

    @Override
    public void prepare() {
        player.prepare();
    }

    @Override
    public int getPlaybackState() {
        return player.getPlaybackState();
    }

    @Override
    public int getPlaybackSuppressionReason() {
        return player.getPlaybackSuppressionReason();
    }

    @Override
    public boolean isPlaying() {
        return player.isPlaying();
    }

    @Nullable
    @Override
    public @org.jspecify.annotations.Nullable PlaybackException getPlayerError() {
        return player.getPlayerError();
    }

    @Override
    public void play() {
        player.play();
    }

    @Override
    public void pause() {
        player.pause();
    }

    @Override
    public void setPlayWhenReady(boolean playWhenReady) {
        player.setPlayWhenReady(playWhenReady);
    }

    @Override
    public boolean getPlayWhenReady() {
        return player.getPlayWhenReady();
    }

    @Override
    public void setRepeatMode(int repeatMode) {
        FlutterIntegration.sendEvent("loop", Map.of("loop", repeatMode == REPEAT_MODE_ALL));
        listeners.forEach(listener -> listener.onRepeatModeChanged(repeatMode == REPEAT_MODE_ALL ? REPEAT_MODE_ALL : REPEAT_MODE_OFF));
    }

    @Override
    public int getRepeatMode() {
        return loop ? REPEAT_MODE_ALL : REPEAT_MODE_OFF;
    }

    @Override
    public void setShuffleModeEnabled(boolean shuffleModeEnabled) {
        // not supported
    }

    @Override
    public boolean getShuffleModeEnabled() {
        return player.getShuffleModeEnabled();
    }

    @Override
    public boolean isLoading() {
        return player.isLoading();
    }

    @Override
    public void seekToDefaultPosition() {
        seekTo(C.TIME_UNSET);
    }

    @Override
    public void seekToDefaultPosition(int mediaItemIndex) {
        seekTo(mediaItemIndex, C.TIME_UNSET);
    }

    @Override
    public void seekTo(long positionMs) {
        if (positionMs == C.TIME_UNSET) {
            positionMs = 0;
        }
        if (player.isCurrentMediaItemSeekable() && positionOffsetMs == 0) {
            player.seekTo(positionMs);
            return;
        }
        final var mediaItem = player.getCurrentMediaItem();
        if (mediaItem == null || mediaItem.localConfiguration == null) return;
        final Uri uri = mediaItem.localConfiguration.uri;
        final Uri newUri = setUriTimeOffset(uri, positionMs);
        positionOffsetMs = positionMs;
        player.replaceMediaItem(player.getCurrentMediaItemIndex(), mediaItem.buildUpon().setUri(newUri).build());
    }

    @Override
    public void seekTo(int mediaItemIndex, long positionMs) {
        // TODO
    }

    @Override
    public long getSeekBackIncrement() {
        return player.getSeekBackIncrement();
    }

    @Override
    public void seekBack() {
        // TODO handle by calling seek to
    }

    @Override
    public long getSeekForwardIncrement() {
        return player.getSeekForwardIncrement();
    }

    @Override
    public void seekForward() {
        // TODO handle by calling seek to
    }

    @Override
    public boolean hasPreviousMediaItem() {
        // TODO handle with flutter
        return true;
    }

    @Override
    public void seekToPreviousMediaItem() {
        FlutterIntegration.sendEvent("playPrev", null);
    }

    @Override
    public long getMaxSeekToPreviousPosition() {
        return 3000;
    }

    @Override
    public void seekToPrevious() {
        if (getCurrentPosition() > 3000) {
            seekTo(0);
            return;
        }
        seekToPreviousMediaItem();
    }

    @Override
    public boolean hasNextMediaItem() {
        if (player.hasNextMediaItem()) {
            return true;
        }
        // TODO handle with flutter
        return true;
    }

    @Override
    public void seekToNextMediaItem() {
        if (player.hasNextMediaItem()) {
            player.seekToNextMediaItem();
            return;
        }
        FlutterIntegration.sendEvent("playNext", null);
    }

    @Override
    public void seekToNext() {
        seekToNextMediaItem();
    }

    @Override
    public void setPlaybackParameters(@NonNull PlaybackParameters playbackParameters) {
        player.setPlaybackParameters(playbackParameters);
    }

    @Override
    public void setPlaybackSpeed(float speed) {
        // not supported (because UI relies on 1x speed)
    }

    @Override
    public @NonNull PlaybackParameters getPlaybackParameters() {
        return player.getPlaybackParameters();
    }

    @Override
    public void stop() {
        if (treatStopAsPause) {
            pause();
            return;
        }
        player.clearMediaItems();
        player.stop();
    }

    @Override
    public void release() {
        unregisterMethodHandlers();
        player.release();
    }

    @Override
    public @NonNull Tracks getCurrentTracks() {
        return player.getCurrentTracks();
    }

    @Override
    public @NonNull TrackSelectionParameters getTrackSelectionParameters() {
        return player.getTrackSelectionParameters();
    }

    @Override
    public void setTrackSelectionParameters(@NonNull TrackSelectionParameters parameters) {
        player.setTrackSelectionParameters(parameters);
    }

    @Override
    public @NonNull MediaMetadata getMediaMetadata() {
        return player.getMediaMetadata();
    }

    @Override
    public @NonNull MediaMetadata getPlaylistMetadata() {
        return player.getPlaylistMetadata();
    }

    @Override
    public void setPlaylistMetadata(@NonNull MediaMetadata mediaMetadata) {
        player.setPlaylistMetadata(mediaMetadata);
    }

    @Nullable
    @Override
    public @org.jspecify.annotations.Nullable Object getCurrentManifest() {
        return null;
        // return player.getCurrentManifest();
    }

    @Override
    public @NonNull Timeline getCurrentTimeline() {
        return new CustomTimeline(player.getCurrentTimeline());
    }

    @Override
    public int getCurrentPeriodIndex() {
        return player.getCurrentPeriodIndex();
    }

    @Deprecated
    @Override
    public int getCurrentWindowIndex() {
        return player.getCurrentWindowIndex();
    }

    @Override
    public int getCurrentMediaItemIndex() {
        return player.getCurrentMediaItemIndex();
    }

    @Deprecated
    @Override
    public int getNextWindowIndex() {
        return player.getNextWindowIndex();
    }

    @Override
    public int getNextMediaItemIndex() {
        return player.getNextMediaItemIndex();
    }

    @Deprecated
    @Override
    public int getPreviousWindowIndex() {
        return player.getPreviousWindowIndex();
    }

    @Override
    public int getPreviousMediaItemIndex() {
        return player.getPreviousMediaItemIndex();
    }

    @Nullable
    @Override
    public @org.jspecify.annotations.Nullable MediaItem getCurrentMediaItem() {
        return player.getCurrentMediaItem();
    }

    @Override
    public int getMediaItemCount() {
        return player.getMediaItemCount();
    }

    @Override
    public @NonNull MediaItem getMediaItemAt(int index) {
        return player.getMediaItemAt(index);
    }

    @Override
    public long getDuration() {
        final var mediaItem = player.getCurrentMediaItem();
        if (mediaItem == null) return 0;
        final Long duration = mediaItem.mediaMetadata.durationMs;
        if (duration != null) return duration;
        return player.getDuration();
    }

    @Override
    public int getBufferedPercentage() {
        return player.getBufferedPercentage();
    }

    @Override
    public long getTotalBufferedDuration() {
        return player.getTotalBufferedDuration();
    }

    @Deprecated
    @Override
    public boolean isCurrentWindowDynamic() {
        return player.isCurrentWindowDynamic();
    }

    @Override
    public boolean isCurrentMediaItemDynamic() {
        return player.isCurrentMediaItemDynamic();
    }

    @Deprecated
    @Override
    public boolean isCurrentWindowLive() {
        return false;
    }

    @Override
    public boolean isCurrentMediaItemLive() {
        return false;
    }

    @Override
    public long getCurrentLiveOffset() {
        return player.getCurrentLiveOffset();
    }

    @Deprecated
    @Override
    public boolean isCurrentWindowSeekable() {
        return true;
    }

    @Override
    public boolean isCurrentMediaItemSeekable() {
        return true;
    }

    @Override
    public boolean isPlayingAd() {
        return player.isPlayingAd();
    }

    @Override
    public int getCurrentAdGroupIndex() {
        return player.getCurrentAdGroupIndex();
    }

    @Override
    public int getCurrentAdIndexInAdGroup() {
        return player.getCurrentAdIndexInAdGroup();
    }

    @Override
    public long getContentDuration() {
        return player.getContentDuration();
    }

    @Override
    public long getContentPosition() {
        return getCurrentPosition();
    }

    @Override
    public long getContentBufferedPosition() {
        return getBufferedPosition();
    }

    @Override
    public @NonNull AudioAttributes getAudioAttributes() {
        return player.getAudioAttributes();
    }

    @Override
    public void setVolume(float volume) {
        player.setVolume(volume);
    }

    @Override
    public float getVolume() {
        return player.getVolume();
    }

    @Override
    public void mute() {
        player.mute();
    }

    @Override
    public void unmute() {
        player.unmute();
    }

    @Override
    public void clearVideoSurface() {
        player.clearVideoSurface();
    }

    @Override
    public void clearVideoSurface(@Nullable @org.jspecify.annotations.Nullable Surface surface) {
        player.clearVideoSurface(surface);
    }

    @Override
    public void setVideoSurface(@Nullable @org.jspecify.annotations.Nullable Surface surface) {
        player.setVideoSurface(surface);
    }

    @Override
    public void setVideoSurfaceHolder(@Nullable @org.jspecify.annotations.Nullable SurfaceHolder surfaceHolder) {
        player.setVideoSurfaceHolder(surfaceHolder);
    }

    @Override
    public void clearVideoSurfaceHolder(@Nullable @org.jspecify.annotations.Nullable SurfaceHolder surfaceHolder) {
        player.clearVideoSurfaceHolder(surfaceHolder);
    }

    @Override
    public void setVideoSurfaceView(@Nullable @org.jspecify.annotations.Nullable SurfaceView surfaceView) {
        player.setVideoSurfaceView(surfaceView);
    }

    @Override
    public void clearVideoSurfaceView(@Nullable @org.jspecify.annotations.Nullable SurfaceView surfaceView) {
        player.clearVideoSurfaceView(surfaceView);
    }

    @Override
    public void setVideoTextureView(@Nullable @org.jspecify.annotations.Nullable TextureView textureView) {
        player.setVideoTextureView(textureView);
    }

    @Override
    public void clearVideoTextureView(@Nullable @org.jspecify.annotations.Nullable TextureView textureView) {
        player.clearVideoTextureView(textureView);
    }

    @Override
    public @NonNull VideoSize getVideoSize() {
        return player.getVideoSize();
    }

    @Override
    public @NonNull Size getSurfaceSize() {
        return player.getSurfaceSize();
    }

    @Override
    public @NonNull CueGroup getCurrentCues() {
        return player.getCurrentCues();
    }

    @Override
    public @NonNull DeviceInfo getDeviceInfo() {
        return player.getDeviceInfo();
    }

    @Override
    public int getDeviceVolume() {
        return player.getDeviceVolume();
    }

    @Override
    public boolean isDeviceMuted() {
        return player.isDeviceMuted();
    }

    @Deprecated
    @Override
    public void setDeviceVolume(int volume) {
        player.setDeviceVolume(volume);
    }

    @Override
    public void setDeviceVolume(int volume, int flags) {
        player.setDeviceVolume(volume, flags);
    }

    @Deprecated
    @Override
    public void increaseDeviceVolume() {
        player.increaseDeviceVolume();
    }

    @Override
    public void increaseDeviceVolume(int flags) {
        player.increaseDeviceVolume(flags);
    }

    @Deprecated
    @Override
    public void decreaseDeviceVolume() {
        player.decreaseDeviceVolume();
    }

    @Override
    public void decreaseDeviceVolume(int flags) {
        player.decreaseDeviceVolume(flags);
    }

    @Deprecated
    @Override
    public void setDeviceMuted(boolean muted) {
        player.setDeviceMuted(muted);
    }

    @Override
    public void setDeviceMuted(boolean muted, int flags) {
        player.setDeviceMuted(muted, flags);
    }

    @Override
    public void setAudioAttributes(@NonNull AudioAttributes audioAttributes, boolean handleAudioFocus) {
        player.setAudioAttributes(audioAttributes, handleAudioFocus);
    }

    private class PlayerListener implements Listener {
        @Override
        public void onEvents(@NonNull Player player, @NonNull Events events) {
            listeners.forEach(listener -> listener.onEvents(player, events));
        }

        @Override
        public void onTimelineChanged(@NonNull Timeline timeline, @TimelineChangeReason int reason) {
            final var t = new CustomTimeline(timeline);
            listeners.forEach(listener -> listener.onTimelineChanged(t, reason));
        }

        @Override
        public void onMediaItemTransition(
                @Nullable MediaItem mediaItem, @MediaItemTransitionReason int reason) {
            if (reason == MEDIA_ITEM_TRANSITION_REASON_AUTO || reason == MEDIA_ITEM_TRANSITION_REASON_SEEK) {
                positionOffsetMs = 0;
                FlutterIntegration.sendEvent("advance", null);
            }
            listeners.forEach(listener -> listener.onMediaItemTransition(mediaItem, reason));
        }

        @Override
        public void onTracksChanged(@NonNull Tracks tracks) {
            listeners.forEach(listener -> listener.onTracksChanged(tracks));
        }

        @Override
        public void onMediaMetadataChanged(@NonNull MediaMetadata mediaMetadata) {
            listeners.forEach(listener -> listener.onMediaMetadataChanged(mediaMetadata));
        }

        @Override
        public void onPlaylistMetadataChanged(@NonNull MediaMetadata mediaMetadata) {
            listeners.forEach(listener -> listener.onPlaylistMetadataChanged(mediaMetadata));
        }

        @Override
        public void onIsLoadingChanged(boolean isLoading) {
            listeners.forEach(listener -> listener.onIsLoadingChanged(isLoading));
        }

        @Deprecated
        @UnstableApi
        @Override
        public void onLoadingChanged(boolean isLoading) {
            listeners.forEach(listener -> listener.onLoadingChanged(isLoading));
        }

        public void onAvailableCommandsChanged(@NonNull Commands availableCommands) {}

        public void onTrackSelectionParametersChanged(@NonNull TrackSelectionParameters parameters) {
            listeners.forEach(listener -> listener.onTrackSelectionParametersChanged(parameters));
        }

        @Deprecated
        @UnstableApi
        public void onPlayerStateChanged(boolean playWhenReady, @State int playbackState) {
            listeners.forEach(listener -> listener.onPlayerStateChanged(playWhenReady, playbackState));
        }

        @Override
        public void onPlaybackStateChanged(@State int playbackState) {
            switch (playbackState) {
                case STATE_IDLE -> {
                    FlutterIntegration.sendEvent("state", Map.of(
                            "state", "stopped"
                    ));
                }
                case STATE_ENDED -> FlutterIntegration.sendEvent("state", Map.of(
                        "state", "stopped"
                ));
                case STATE_BUFFERING ->  FlutterIntegration.sendEvent("state", Map.of(
                        "state", "loading"
                ));
                case STATE_READY ->  FlutterIntegration.sendEvent("state", Map.of(
                        "state", player.isPlaying() ? "playing" : "paused"
                ));
            }
            listeners.forEach(listener -> listener.onPlaybackStateChanged(playbackState));
        }

        @Override
        public void onPlayWhenReadyChanged(
                boolean playWhenReady, @PlayWhenReadyChangeReason int reason) {
            listeners.forEach(listener -> listener.onPlayWhenReadyChanged(playWhenReady, reason));
        }

        @Override
        public void onPlaybackSuppressionReasonChanged(
                @PlaybackSuppressionReason int playbackSuppressionReason) {
            listeners.forEach(listener -> listener.onPlaybackSuppressionReasonChanged(playbackSuppressionReason));
        }

        @Override
        public void onIsPlayingChanged(boolean isPlaying) {
            if (player.getPlaybackState() == STATE_READY) {
                FlutterIntegration.sendEvent("state", Map.of(
                        "state", isPlaying ? "playing" : "paused"
                ));
            }
            listeners.forEach(listener -> listener.onIsPlayingChanged(isPlaying));
        }

        @Override
        public void onRepeatModeChanged(@RepeatMode int repeatMode) {}

        @Override
        public void onShuffleModeEnabledChanged(boolean shuffleModeEnabled) {
            listeners.forEach(listener -> listener.onShuffleModeEnabledChanged(shuffleModeEnabled));
        }

        @Override
        public void onPlayerError(@NonNull PlaybackException error) {
            // TODO send to flutter
            Log.e("Player Error", error.toString());
            listeners.forEach(listener -> listener.onPlayerError(error));
        }

        @Override
        public void onPlayerErrorChanged(@Nullable PlaybackException error) {
            listeners.forEach(listener -> listener.onPlayerErrorChanged(error));
        }

        @Deprecated
        @UnstableApi
        @Override
        public void onPositionDiscontinuity(@DiscontinuityReason int reason) {
            listeners.forEach(listener -> listener.onPositionDiscontinuity(reason));
        }

        @Override
        public void onPositionDiscontinuity(
                @NonNull PositionInfo oldPosition, @NonNull PositionInfo newPosition, @DiscontinuityReason int reason) {
            if (reason == Player.DISCONTINUITY_REASON_INTERNAL && newPosition.positionMs < oldPosition.positionMs && newPosition.positionMs < 2000) {
                seekTo(oldPosition.positionMs+positionOffsetMs);
                return;
            }

            final PositionInfo adjustedNewPosition = new PositionInfo(newPosition.windowUid, newPosition.mediaItemIndex, newPosition.mediaItem,
                    newPosition.periodUid, newPosition.periodIndex, newPosition.positionMs + positionOffsetMs,
                    newPosition.contentPositionMs + positionOffsetMs,
                    newPosition.adGroupIndex, newPosition.adIndexInAdGroup);
            listeners.forEach(listener -> listener.onPositionDiscontinuity(oldPosition, adjustedNewPosition, reason));
        }

        @Override
        public void onPlaybackParametersChanged(@NonNull PlaybackParameters playbackParameters) {
            listeners.forEach(listener -> listener.onPlaybackParametersChanged(playbackParameters));
        }

        @Override
        public void onSeekBackIncrementChanged(long seekBackIncrementMs) {
            listeners.forEach(listener -> listener.onSeekBackIncrementChanged(seekBackIncrementMs));
        }

        @Override
        public void onSeekForwardIncrementChanged(long seekForwardIncrementMs) {
            listeners.forEach(listener -> listener.onSeekForwardIncrementChanged(seekForwardIncrementMs));
        }

        @Override
        public void onMaxSeekToPreviousPositionChanged(long maxSeekToPreviousPositionMs) {
            listeners.forEach(listener -> listener.onMaxSeekToPreviousPositionChanged(maxSeekToPreviousPositionMs));
        }

        @UnstableApi
        @Override
        public void onAudioSessionIdChanged(int audioSessionId) {
            listeners.forEach(listener -> listener.onAudioSessionIdChanged(audioSessionId));
        }

        @Override
        public void onAudioAttributesChanged(@NonNull AudioAttributes audioAttributes) {
            listeners.forEach(listener -> listener.onAudioAttributesChanged(audioAttributes));
        }

        @Override
        public void onVolumeChanged(float volume) {
            // TODO notify flutter
            listeners.forEach(listener -> listener.onVolumeChanged(volume));
        }

        @Override
        public void onSkipSilenceEnabledChanged(boolean skipSilenceEnabled) {
            listeners.forEach(listener -> listener.onSkipSilenceEnabledChanged(skipSilenceEnabled));
        }

        @Override
        public void onDeviceInfoChanged(@NonNull DeviceInfo deviceInfo) {
            listeners.forEach(listener -> listener.onDeviceInfoChanged(deviceInfo));
        }

        @Override
        public void onDeviceVolumeChanged(int volume, boolean muted) {
            listeners.forEach(listener -> listener.onDeviceVolumeChanged(volume, muted));
        }

        @Override
        public void onVideoSizeChanged(@NonNull VideoSize videoSize) {
            listeners.forEach(listener -> listener.onVideoSizeChanged(videoSize));
        }

        @Override
        public void onSurfaceSizeChanged(int width, int height) {
            listeners.forEach(listener -> listener.onSurfaceSizeChanged(width, height));
        }

        @Override
        public void onRenderedFirstFrame() {
            listeners.forEach(Listener::onRenderedFirstFrame);
        }

        @Deprecated
        @UnstableApi
        @Override
        public void onCues(@NonNull List<Cue> cues) {
            listeners.forEach(listener -> listener.onCues(cues));
        }

        @Override
        public void onCues(@NonNull CueGroup cueGroup) {
            listeners.forEach(listener -> listener.onCues(cueGroup));
        }

        @UnstableApi
        @Override
        public void onMetadata(@NonNull Metadata metadata) {
            listeners.forEach(listener -> listener.onMetadata(metadata));
        }
    }

    @SuppressWarnings("deprecation")
    static final Commands availableCommands = new Commands.Builder().addAll(
            COMMAND_PLAY_PAUSE,
            COMMAND_PREPARE,
            COMMAND_STOP,
            COMMAND_SEEK_TO_DEFAULT_POSITION,
            COMMAND_SEEK_IN_CURRENT_MEDIA_ITEM,
            COMMAND_SEEK_TO_PREVIOUS_MEDIA_ITEM,
            COMMAND_SEEK_TO_NEXT_MEDIA_ITEM,
            COMMAND_SEEK_TO_PREVIOUS,
            COMMAND_SEEK_TO_NEXT,
            COMMAND_SET_REPEAT_MODE,
            COMMAND_GET_CURRENT_MEDIA_ITEM,
            COMMAND_GET_AUDIO_ATTRIBUTES,
            COMMAND_GET_METADATA,
            COMMAND_GET_TIMELINE,
            COMMAND_GET_VOLUME,
            COMMAND_GET_DEVICE_VOLUME,
            COMMAND_SET_VOLUME,
            COMMAND_SET_DEVICE_VOLUME,
            COMMAND_SET_DEVICE_VOLUME_WITH_FLAGS,
            COMMAND_ADJUST_DEVICE_VOLUME,
            COMMAND_ADJUST_DEVICE_VOLUME_WITH_FLAGS,
            COMMAND_SET_AUDIO_ATTRIBUTES,
            COMMAND_RELEASE,
            COMMAND_SET_MEDIA_ITEM,
            COMMAND_CHANGE_MEDIA_ITEMS
    ).build();
}
