package org.crossonic.app;

import androidx.annotation.OptIn;
import androidx.media3.common.ForwardingSimpleBasePlayer;
import androidx.media3.common.Player;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.session.MediaSession;
import androidx.media3.session.MediaSessionService;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import org.jspecify.annotations.NonNull;

public class PlaybackService extends MediaSessionService {
    private MediaSession mediaSession = null;
    private Player player;

    @OptIn(markerClass = UnstableApi.class)
    @Override
    public void onCreate() {
        super.onCreate();

        player = new ExoPlayer.Builder(this).build();
        mediaSession = new MediaSession.Builder(this, new ForwardingSimpleBasePlayer(player){
            // TODO
        }).build();
        registerMethodCallbacks();
    }

    private void registerMethodCallbacks() {
        FlutterIntegration.addMethodCallback("player.play", this::onPlay);
        FlutterIntegration.addMethodCallback("player.pause", this::onPause);
    }

    private void unregisterMethodCallbacks() {
        FlutterIntegration.removeMethodCallback("player.play", this::onPlay);
        FlutterIntegration.removeMethodCallback("player.pause", this::onPause);
    }

    private void onPlay(MethodCall call, MethodChannel.Result result){
        player.play();
        result.success(null);
    }

    private void onPause(MethodCall call, MethodChannel.Result result){
        player.pause();
        result.success(null);
    }

    @Override
    public MediaSession onGetSession(MediaSession.@NonNull ControllerInfo controllerInfo) {
        return mediaSession;
    }

    @Override
    public void onDestroy() {
        unregisterMethodCallbacks();
        mediaSession.getPlayer().release();
        mediaSession.release();
        mediaSession = null;
        super.onDestroy();
    }
}
