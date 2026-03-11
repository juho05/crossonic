package org.crossonic.app;

import android.app.PendingIntent;
import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.Nullable;
import androidx.annotation.OptIn;
import androidx.media3.common.MediaItem;
import androidx.media3.common.MediaMetadata;
import androidx.media3.common.Player;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.session.*;
import com.google.common.collect.ImmutableList;
import com.google.common.util.concurrent.*;
import org.jspecify.annotations.NonNull;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class PlaybackService extends MediaLibraryService {
    private MediaLibrarySession mediaSession;

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

        final MediaLibrarySession.Callback callback = new SessionCallback();
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

            final var extras = new Bundle();
            extras.putInt(MediaConstants.EXTRAS_KEY_CONTENT_STYLE_BROWSABLE, MediaConstants.EXTRAS_VALUE_CONTENT_STYLE_LIST_ITEM);
            extras.putInt(MediaConstants.EXTRAS_KEY_CONTENT_STYLE_PLAYABLE, MediaConstants.EXTRAS_VALUE_CONTENT_STYLE_LIST_ITEM);

            final var libraryParams = new LibraryParams.Builder().setOffline(params != null && params.isOffline).setExtras(extras).build();
            return Futures.immediateFuture(LibraryResult.ofItem(item, libraryParams));
        }

        @OptIn(markerClass = UnstableApi.class)
        @Override
        @SuppressWarnings("unchecked")
        public @NonNull ListenableFuture<LibraryResult<ImmutableList<MediaItem>>> onGetChildren(@NonNull MediaLibrarySession session, MediaSession.@NonNull ControllerInfo browser, @NonNull String parentId, int page, int pageSize, @Nullable MediaLibraryService.LibraryParams params) {
            final Map<Object, Object> msgParams = new HashMap<>();
            msgParams.put("parentId", parentId);
            if (pageSize < Integer.MAX_VALUE) {
                msgParams.put("page", page);
                msgParams.put("pageSize", pageSize);
            }
            if (params != null) {
                msgParams.put("isOffline", params.isOffline);
                msgParams.put("isRecent", params.isRecent);
                msgParams.put("isSuggested", params.isSuggested);
            }
            final var future = FlutterIntegration.invokeMethod("onGetChildren", msgParams);
            return Futures.transformAsync(future, result -> Futures.immediateFuture(Mappings.buildLibraryResultMediaItemsFromMsg((Map<Object,Object>) result)), MoreExecutors.directExecutor());
        }

        @Override
        @SuppressWarnings("unchecked")
        public @NonNull ListenableFuture<LibraryResult<ImmutableList<MediaItem>>> onGetSearchResult(@NonNull MediaLibrarySession session, MediaSession.@NonNull ControllerInfo browser, @NonNull String query, int page, int pageSize, @Nullable MediaLibraryService.LibraryParams params) {
            final Map<Object, Object> msgParams = new HashMap<>();
            msgParams.put("query", query);
            if (pageSize < Integer.MAX_VALUE) {
                msgParams.put("page", page);
                msgParams.put("pageSize", pageSize);
            }
            if (params != null) {
                msgParams.put("isOffline", params.isOffline);
                msgParams.put("isRecent", params.isRecent);
                msgParams.put("isSuggested", params.isSuggested);
            }
            final var future = FlutterIntegration.invokeMethod("onGetSearchResult", msgParams);
            return Futures.transformAsync(future, result -> Futures.immediateFuture(Mappings.buildLibraryResultMediaItemsFromMsg((Map<Object,Object>)result)), MoreExecutors.directExecutor());
        }

        @Override
        public @NonNull ListenableFuture<LibraryResult<Void>> onSearch(@NonNull MediaLibrarySession session, MediaSession.@NonNull ControllerInfo browser, @NonNull String query, @Nullable MediaLibraryService.LibraryParams params) {
            final Map<Object, Object> msgParams = new HashMap<>();
            msgParams.put("query", query);
            if (params != null) {
                msgParams.put("isOffline", params.isOffline);
                msgParams.put("isRecent", params.isRecent);
                msgParams.put("isSuggested", params.isSuggested);
            }
            final var future = FlutterIntegration.invokeMethod("onSearch", msgParams);
            return Futures.transformAsync(future, result -> {
                mediaSession.notifySearchResultChanged(browser, query, ((Number)result).intValue(), params);
                return Futures.immediateFuture(LibraryResult.ofVoid(params));
            }, MoreExecutors.directExecutor());
        }

        @Override
        public @NonNull ListenableFuture<List<MediaItem>> onAddMediaItems(@NonNull MediaSession mediaSession, MediaSession.@NonNull ControllerInfo controller, @NonNull List<MediaItem> mediaItems) {
            return Futures.immediateFuture(mediaItems);
        }

        @OptIn(markerClass = UnstableApi.class)
        @Override
        public MediaSession.@NonNull ConnectionResult onConnect(@NonNull MediaSession session, MediaSession.@NonNull ControllerInfo controller) {
            if (!controller.isTrusted()) {
                return MediaSession.ConnectionResult.reject();
            }
            if (session.isMediaNotificationController(controller)) {
                return new MediaSession.ConnectionResult.AcceptedResultBuilder(session)
                        .setAvailableSessionCommands(MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon().add(CUSTOM_COMMAND_STOP).build())
                        .build();
            }
            return new MediaSession.ConnectionResult.AcceptedResultBuilder(session).build();
        }

        @Override
        public @NonNull ListenableFuture<SessionResult> onCustomCommand(@NonNull MediaSession session, MediaSession.@NonNull ControllerInfo controller, SessionCommand customCommand, @NonNull Bundle args) {
            if (customCommand.customAction.equals(CUSTOM_COMMAND_STOP.customAction)) {
                session.getPlayer().stop();
                return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS));
            }
            return MediaLibrarySession.Callback.super.onCustomCommand(session, controller, customCommand, args);
        }
    }
}
