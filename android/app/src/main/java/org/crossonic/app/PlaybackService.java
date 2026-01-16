package org.crossonic.app;

import android.app.PendingIntent;
import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.OptIn;
import androidx.media3.common.Player;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.session.*;
import com.google.common.collect.ImmutableList;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import org.jspecify.annotations.NonNull;

public class PlaybackService extends MediaSessionService {
    private MediaSession mediaSession = null;

    private static final SessionCommand CUSTOM_COMMAND_STOP = new SessionCommand("ACTION_STOP", Bundle.EMPTY);

    @OptIn(markerClass = UnstableApi.class)
    @Override
    public void onCreate() {
        super.onCreate();
        final CommandButton stopButton = new CommandButton.Builder(CommandButton.ICON_STOP).
                setDisplayName("Stop").setSessionCommand(CUSTOM_COMMAND_STOP).build();

        final Player player = new CrossonicPlayer(this);

        Intent intent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        mediaSession = new MediaSession.Builder(this, player).
                setCallback(new CustomCommandCallback()).
                setSessionActivity(pendingIntent).
                setMediaButtonPreferences(ImmutableList.of(stopButton)).build();
    }

    @Override
    public MediaSession onGetSession(MediaSession.@NonNull ControllerInfo controllerInfo) {
        return mediaSession;
    }

    @Override
    public void onDestroy() {
        mediaSession.getPlayer().release();
        mediaSession.release();
        mediaSession = null;
        super.onDestroy();
    }

    private static class CustomCommandCallback implements MediaSession.Callback {
        @OptIn(markerClass = UnstableApi.class)
        @Override
        public MediaSession.@NonNull ConnectionResult onConnect(@NonNull MediaSession session, MediaSession.@NonNull ControllerInfo controller) {
            return new MediaSession.ConnectionResult.AcceptedResultBuilder(session)
                    .setAvailableSessionCommands(MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon().add(CUSTOM_COMMAND_STOP).build())
                    .build();
        }

        @Override
        public @NonNull ListenableFuture<SessionResult> onCustomCommand(@NonNull MediaSession session, MediaSession.@NonNull ControllerInfo controller, SessionCommand customCommand, Bundle args) {
            if (customCommand.customAction.equals(CUSTOM_COMMAND_STOP.customAction)) {
                session.getPlayer().stop();
                return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS));
            }
            return MediaSession.Callback.super.onCustomCommand(session, controller, customCommand, args);
        }
    }
}
