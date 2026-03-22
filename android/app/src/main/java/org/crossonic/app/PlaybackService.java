/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

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
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.MoreExecutors;
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
        CLog.debug("PlaybackService.onCreate", "Created media session", null);
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
        CLog.debug("PlaybackService.onDestroy", "Media session released", null);
        super.onDestroy();
    }

    private class SessionCallback implements MediaLibrarySession.Callback {
        @OptIn(markerClass = UnstableApi.class)
        @Override
        public @NonNull ListenableFuture<LibraryResult<MediaItem>> onGetLibraryRoot(@NonNull MediaLibrarySession session, MediaSession.@NonNull ControllerInfo browser, @Nullable MediaLibraryService.LibraryParams params) {
            CLog.debug("SessionCallback.onGetLibraryRoot", "System requested library root", null);

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
            CLog.debug("SessionCallback.onGetChildren", "System requested children for " + parentId, null);
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
            CLog.debug("SessionCallback.onGetChildren", "System requested search result for query: " + query, null);
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
            CLog.debug("SessionCallback.onGetChildren", "System requested search for query: " + query, null);
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
            CLog.trace("SessionCallback.onAddMediaItems", "Immediately returning media items without modification", null);
            return Futures.immediateFuture(mediaItems);
        }

        @OptIn(markerClass = UnstableApi.class)
        @Override
        public MediaSession.@NonNull ConnectionResult onConnect(@NonNull MediaSession session, MediaSession.@NonNull ControllerInfo controller) {
            if (!controller.isTrusted()) {
                CLog.error("SessionCallback.onConnect", "Rejected connection attempt by " + controller.getPackageName() + " because it is not trusted", null);
                return MediaSession.ConnectionResult.reject();
            }
            if (session.isMediaNotificationController(controller)) {
                CLog.debug("SessionCallback.onConnect", "Connected to " + controller.getPackageName() + " with session commands", null);
                return new MediaSession.ConnectionResult.AcceptedResultBuilder(session)
                        .setAvailableSessionCommands(MediaSession.ConnectionResult.DEFAULT_SESSION_COMMANDS.buildUpon().add(CUSTOM_COMMAND_STOP).build())
                        .build();
            }
            CLog.debug("SessionCallback.onConnect", "Connected to " + controller.getPackageName() + " without session commands", null);
            return new MediaSession.ConnectionResult.AcceptedResultBuilder(session).build();
        }

        @Override
        public @NonNull ListenableFuture<SessionResult> onCustomCommand(@NonNull MediaSession session, MediaSession.@NonNull ControllerInfo controller, SessionCommand customCommand, @NonNull Bundle args) {
            if (customCommand.customAction.equals(CUSTOM_COMMAND_STOP.customAction)) {
                CLog.debug("SessionCallback.onCustomCommand", "Received stop command, stopping player", null);
                session.getPlayer().stop();
                return Futures.immediateFuture(new SessionResult(SessionResult.RESULT_SUCCESS));
            }
            CLog.warn("SessionCallback.onCustomCommand", "Received unknown custom command: " + customCommand.customAction, null);
            return MediaLibrarySession.Callback.super.onCustomCommand(session, controller, customCommand, args);
        }
    }
}
