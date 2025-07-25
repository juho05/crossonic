package org.crossonic.audio_player;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.OptIn;
import androidx.annotation.UiThread;
import androidx.media3.common.C;
import androidx.media3.common.MediaItem;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.common.TrackSelectionParameters;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.datasource.cache.CacheDataSource;
import androidx.media3.datasource.cache.SimpleCache;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.Renderer;
import androidx.media3.exoplayer.RenderersFactory;
import androidx.media3.exoplayer.audio.MediaCodecAudioRenderer;
import androidx.media3.exoplayer.mediacodec.MediaCodecSelector;
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory;
import androidx.media3.extractor.DefaultExtractorsFactory;
import androidx.media3.extractor.Extractor;
import androidx.media3.extractor.ExtractorsFactory;
import androidx.media3.extractor.mp3.Mp3Extractor;
import androidx.media3.extractor.mp4.FragmentedMp4Extractor;
import androidx.media3.extractor.mp4.Mp4Extractor;
import androidx.media3.extractor.text.SubtitleParser;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class AudioPlayer implements Player.Listener {
    private static Context _context;

    private static AudioPlayer _instance;

    public static AudioPlayer getInstance(Context context) {
        _context = context;
        if (_instance == null) {
            _instance = new AudioPlayer(_context);
        }
        return _instance;
    }

    private AudioPlayer() {};

    private EventChannel.EventSink _events;

    private ExoPlayer _player;

    AudioPlayer(Context context) {
        _context = context;
    }

    public void updateEventSink(EventChannel.EventSink eventSink) {
        _events = eventSink;
    }

    /** @noinspection DataFlowIssue*/
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "init": init(); break;
            case "dispose": dispose(); break;
            case "play": play(); break;
            case "pause": pause(); break;
            case "seek": seek(call.argument("pos")); break;
            case "setCurrent": setCurrent(call.argument("uri"), call.argument("nextUri"), call.argument("pos")); break;
            case "setNext": setNext(call.argument("uri")); break;
            case "stop": stop(); break;
            case "setVolume": setVolume(call.argument("volume")); break;
            case "getPosition": result.success(getPosition()); return;
            case "getBufferedPosition": result.success(getBufferedPosition()); return;
            default: result.notImplemented(); return;
        }
        result.success(null);
    }

    @OptIn(markerClass = UnstableApi.class)
    private void init() {
        if (_player != null) return;

        // only enable audio renderers to allow unused renderers to be removed by code shrinking
        RenderersFactory audioOnlyRenderersFactory =
                (handler, videoListener, audioListener, textOutput, metadataOutput) ->
                    new Renderer[]{
                        new MediaCodecAudioRenderer(_context, MediaCodecSelector.DEFAULT, handler, audioListener)
                    };

        final ExoPlayer.Builder builder = new ExoPlayer.Builder(_context, audioOnlyRenderersFactory);
        // enable seeking in MP3 files and other files that only support constant bitrate seeking
        builder.setMediaSourceFactory(new DefaultMediaSourceFactory(_context, new DefaultExtractorsFactory().setConstantBitrateSeekingEnabled(true)));
        _player = builder.build();
        // enable audio offload for decreased battery usage
        _player.setTrackSelectionParameters(
                _player.getTrackSelectionParameters().buildUpon().
                        setAudioOffloadPreferences(new TrackSelectionParameters.AudioOffloadPreferences.Builder()
                                .setAudioOffloadMode(TrackSelectionParameters.AudioOffloadPreferences.AUDIO_OFFLOAD_MODE_ENABLED)
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
        _player.addListener(this);
    }

    private void dispose() {
        if (_player == null) return;
        _player.removeListener(this);
        _player.release();
        _player = null;
    }

    private void play() {
        _player.play();
    }

    private void pause() {
        _player.pause();
    }

    private void seek(int pos) {
        _player.seekTo(pos);
    }

    private void setCurrent(String uri, String nextUri, int pos) {
        if (uri == null) {
            _player.clearMediaItems();
            return;
        }
        List<MediaItem> items = new ArrayList<>();
        items.add(MediaItem.fromUri(uri));
        if (nextUri != null) {
            items.add(MediaItem.fromUri(nextUri));
        }
        Log.d("AudioPlayer", "Replace playlist with " + items.size() + " items");
        _player.setMediaItems(items, 0, pos == 0 ? C.TIME_UNSET : pos);
        _player.prepare();
    }

    private void setNext(String uri) {
        if (_player == null) return;
        if (uri == null) {
            Log.d("AudioPlayer", "Clear next uri");
            _player.removeMediaItem(_player.getCurrentMediaItemIndex()+1);
            return;
        }
        if (_player.getMediaItemCount() > _player.getCurrentMediaItemIndex()+1) {
            Log.d("AudioPlayer", "Replace next uri");
            _player.replaceMediaItem(_player.getCurrentMediaItemIndex()+1, MediaItem.fromUri(uri));
        } else {
            Log.d("AudioPlayer", "Add next uri");
            _player.addMediaItem(MediaItem.fromUri(uri));
        }
    }

    private void stop() {
        if (_player == null) return;
        _player.stop();
    }

    private void setVolume(double volume) {
        if (_player == null) return;
        _player.setVolume((float)volume);
    }

    private int getPosition() {
        if (_player == null) return 0;
        return (int)_player.getCurrentPosition();
    }

    private int getBufferedPosition() {
        if (_player == null) return 0;
        return (int)_player.getBufferedPosition();
    }

    private int _playbackState = Player.STATE_IDLE;
    private boolean _playing = false;

    @Override
    public void onIsPlayingChanged(boolean isPlaying) {
        _playing = isPlaying;
        sendPlaybackStateEvent();
    }

    @Override
    public void onPlaybackStateChanged(int playbackState) {
        if (_playbackState == playbackState) return;
        Log.d("AudioPlayer", "State: " + playbackState);
        _playbackState = playbackState;
        _playing = false;
        sendPlaybackStateEvent();
    }

    @Override
    public void onPlayerError(@NonNull PlaybackException error) {
        Log.e("AudioPlayer", "Player Error: " + error.toString());
        sendError("PLAYER_ERROR:"+ error.getErrorCodeName(), error.getMessage(), null);
    }

    @Override
    public void onMediaItemTransition(@Nullable MediaItem mediaItem, int reason) {
        Log.d("AudioPlayer", "Transition: " + reason);
        if (reason != Player.MEDIA_ITEM_TRANSITION_REASON_AUTO) return;
        sendEvent("advance", null);
    }

    private static final String _stateStopped = "stopped";
    private static final String _stateLoading = "loading";
    private static final String _statePaused = "paused";
    private static final String _statePlaying = "playing";

    private void sendPlaybackStateEvent() {
        final String state;
        switch (_playbackState) {
            case Player.STATE_BUFFERING:
                state = _stateLoading;
                break;
            case Player.STATE_READY:
                state = _playing ? _statePlaying : _statePaused;
                break;
            case Player.STATE_ENDED:
                state = _stateStopped;
                break;
            default:
                // STATE_IDLE should not send a stopped event
                return;
        }
        final Map<String, Object> data = new HashMap<>();
        data.put("state", state);
        sendEvent("state", data);
    }

    @Override
    public void onPositionDiscontinuity(@NonNull Player.PositionInfo oldPosition, @NonNull Player.PositionInfo newPosition, int reason) {
        Log.d("AudioPlayer", "Position Discontinuity: " + oldPosition.positionMs + "ms -> " + newPosition.positionMs + "ms, reason: " + reason);
        if (reason == Player.DISCONTINUITY_REASON_INTERNAL && newPosition.positionMs < oldPosition.positionMs && oldPosition.positionMs - newPosition.positionMs > 1000) {
            _player.pause();
            final Map<String, Object> data = new HashMap<>();
            data.put("pos", (int)oldPosition.positionMs);
            sendEvent("restart", data);
        }
    }

    private void sendEvent(String name, Map<String, Object> data) {
        if (_events == null) return;
        final Map<String, Object> map = new HashMap<>();
        map.put("name", name);
        if (data != null) {
            map.put("data", data);
        }
        _events.success(map);
    }

    private void sendError(String errorCode, String errorMessage, Object errorDetails) {
        if (_events == null) return;
        _events.error(errorCode, errorMessage, errorDetails);
    }
}
