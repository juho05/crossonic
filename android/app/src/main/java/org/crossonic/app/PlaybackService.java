package org.crossonic.app;

import android.app.PendingIntent;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.Nullable;
import androidx.annotation.OptIn;
import androidx.media3.common.MediaItem;
import androidx.media3.common.MediaMetadata;
import androidx.media3.common.Player;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.session.*;
import com.google.common.collect.ImmutableList;
import com.google.common.util.concurrent.*;
import io.flutter.plugin.common.MethodChannel;
import org.jspecify.annotations.NonNull;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

public class PlaybackService extends MediaLibraryService {
    private MediaLibrarySession mediaSession;
    private MediaLibrarySession.Callback callback;

    private static final SessionCommand CUSTOM_COMMAND_STOP = new SessionCommand("ACTION_STOP", Bundle.EMPTY);

    @OptIn(markerClass = UnstableApi.class)
    @Override
    public void onCreate() {
        super.onCreate();
        final CommandButton stopButton = new CommandButton.Builder(CommandButton.ICON_STOP).
                setDisplayName("Stop").setSessionCommand(CUSTOM_COMMAND_STOP).build();

        final Player player = new CrossonicPlayer(this);

        Intent intent = MainActivity.withCachedEngine(FlutterIntegration.ENGINE_ID).build(this);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        callback = new SessionCallback();
        mediaSession = new MediaLibrarySession.Builder(this, player, callback).
                setSessionActivity(pendingIntent).
                setMediaButtonPreferences(ImmutableList.of(stopButton)).build();
    }

    @Override
    public MediaLibrarySession onGetSession(MediaSession.@NonNull ControllerInfo controllerInfo) {
        return mediaSession;
    }

    @Override
    public void onDestroy() {
        mediaSession.getPlayer().release();
        mediaSession.release();
        mediaSession = null;
        super.onDestroy();
    }

    private class SessionCallback implements MediaLibrarySession.Callback {
        @OptIn(markerClass = UnstableApi.class)
        @Override
        public @NonNull ListenableFuture<LibraryResult<MediaItem>> onGetLibraryRoot(@NonNull MediaLibrarySession session, MediaSession.@NonNull ControllerInfo browser, @Nullable MediaLibraryService.LibraryParams params) {
            final var metadata = new MediaMetadata.Builder().setIsPlayable(false).setIsBrowsable(true).build();
            final var item = new MediaItem.Builder().setMediaId("crossonic_root").setMediaMetadata(metadata).build();
            return Futures.immediateFuture(LibraryResult.ofItem(item, params));
        }

        @OptIn(markerClass = UnstableApi.class)
        @Override
        public @NonNull ListenableFuture<LibraryResult<ImmutableList<MediaItem>>> onGetChildren(@NonNull MediaLibrarySession session, MediaSession.@NonNull ControllerInfo browser, @NonNull String parentId, int page, int pageSize, @Nullable MediaLibraryService.LibraryParams params) {
            Log.e("ANDROIDAUTO", "onGetChildren");
            final HashMap<Object, Object> msgParams = new HashMap<>();
            msgParams.put("parentId", parentId);
            if (params != null) {
                msgParams.put("isOffline", params.isOffline);
                msgParams.put("isRecent", params.isRecent);
                msgParams.put("isSuggested", params.isSuggested);
            }
            final var future = FlutterIntegration.invokeMethod("onGetChildren", msgParams);
            return Futures.transformAsync(future, result -> Futures.immediateFuture(Mappings.buildLibraryResultMediaItemsFromMsg((Map<Object,Object>)result)), MoreExecutors.directExecutor());
        }

        @Override
        public @NonNull ListenableFuture<LibraryResult<MediaItem>> onGetItem(@NonNull MediaLibrarySession session, MediaSession.@NonNull ControllerInfo browser, @NonNull String mediaId) {
            return MediaLibrarySession.Callback.super.onGetItem(session, browser, mediaId);
        }

        @OptIn(markerClass = UnstableApi.class)
        @Override
        public MediaSession.@NonNull ConnectionResult onConnect(@NonNull MediaSession session, MediaSession.@NonNull ControllerInfo controller) {
            if (session.isMediaNotificationController(controller)) {
                return new MediaSession.ConnectionResult.AcceptedResultBuilder(session)
                        .setAvailableSessionCommands(MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon().add(CUSTOM_COMMAND_STOP).build())
                        .build();
            }
            return new MediaSession.ConnectionResult.AcceptedResultBuilder(session).build();
        }

        @Override
        public @NonNull ListenableFuture<SessionResult> onCustomCommand(@NonNull MediaSession session, MediaSession.@NonNull ControllerInfo controller, SessionCommand customCommand, Bundle args) {
            if (customCommand.customAction.equals(CUSTOM_COMMAND_STOP.customAction)) {
                session.getPlayer().stop();
                return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS));
            }
            return MediaLibrarySession.Callback.super.onCustomCommand(session, controller, customCommand, args);
        }
    }
}
