/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package org.crossonic.app;

import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.OptIn;
import androidx.media3.common.MediaItem;
import androidx.media3.common.MediaMetadata;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.session.LibraryResult;
import androidx.media3.session.MediaConstants;
import androidx.media3.session.MediaLibraryService;
import com.google.common.collect.ImmutableList;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static androidx.media3.common.MediaMetadata.PICTURE_TYPE_FRONT_COVER;

public class Mappings {
    public static LibraryResult<ImmutableList<MediaItem>> buildLibraryResultMediaItemsFromMsg(Map<Object, Object> msg) {
        final int resultCode = ((Number)msg.get("resultCode")).intValue();
        if (resultCode != LibraryResult.RESULT_SUCCESS) {
            return LibraryResult.ofError(resultCode);
        }
        final Map<Object, Object> params = (Map<Object, Object>) msg.get("params");
        final var libraryParams = libraryParamsFromMsg(params);

        final List<Object> mediaItems = (List<Object>) msg.get("mediaItems");
        return LibraryResult.ofItemList(mediaItems.stream().map((mi)->{
            final var builder = new MediaItem.Builder();
            buildMediaItemFromMsg(builder, (Map<Object, Object>)mi);
            return builder.build();
        }).collect(Collectors.toList()), libraryParams);
    }

    public static LibraryResult<MediaItem> buildLibraryResultMediaItemFromMsg(Map<Object, Object> msg) {
        Log.d("ANDROIDAUTO", msg.toString());
        final int resultCode = ((Number)msg.get("resultCode")).intValue();
        if (resultCode != LibraryResult.RESULT_SUCCESS) {
            return LibraryResult.ofError(resultCode);
        }

        final Map<Object, Object> params = (Map<Object, Object>) msg.get("params");
        final var libraryParams = libraryParamsFromMsg(params);

        final Map<Object,Object> mi = (Map<Object,Object>) msg.get("mediaItem");

        final var builder = new MediaItem.Builder();
        buildMediaItemFromMsg(builder, mi);
        final var mediaItem = builder.build();

        return LibraryResult.ofItem(mediaItem, libraryParams);
    }

    @OptIn(markerClass = UnstableApi.class)
    private static MediaLibraryService.LibraryParams libraryParamsFromMsg(Map<Object, Object> params) {
        return new MediaLibraryService.LibraryParams.Builder()
                .setOffline((boolean) params.get("isOffline"))
                .setRecent((boolean)params.get("isRecent"))
                .setSuggested((boolean)params.get("isSuggested")).build();
    }

    @OptIn(markerClass = UnstableApi.class)
    public static void buildMediaItemFromMsg(MediaItem.Builder builder, Map<Object, Object> msg) {
        final String id = (String)msg.get("id");
        assert id != null;
        builder.setMediaId(id);

        if (msg.containsKey("uri")) {
            Uri streamUri = Uri.parse((String)msg.get("uri"));
            builder.setUri(streamUri);
        }

        final var metadataBuilder = new MediaMetadata.Builder();
        if (msg.containsKey("browsable")) {
            metadataBuilder.setIsBrowsable((boolean)msg.get("browsable"));
        }
        if (msg.containsKey("playable")) {
            metadataBuilder.setIsPlayable((boolean)msg.get("playable"));
        }
        if (msg.containsKey("title")) {
            metadataBuilder.setTitle((String) msg.get("title"));
        }
        if (msg.containsKey("album")) {
            metadataBuilder.setAlbumTitle((String) msg.get("album"));
        }
        if (msg.containsKey("artist")) {
            metadataBuilder.setArtist((String) msg.get("artist"));
        }
        if (msg.containsKey("discNumber")) {
            metadataBuilder.setDiscNumber(((Number)msg.get("discNumber")).intValue());
        }
        if (msg.containsKey("durationMs")) {
            metadataBuilder.setDurationMs(((Number)msg.get("durationMs")).longValue());
        }
        if (msg.containsKey("genre")) {
            metadataBuilder.setGenre((String)msg.get("genre"));
        }
        if (msg.containsKey("trackNumber")) {
            metadataBuilder.setTrackNumber(((Number)msg.get("trackNumber")).intValue());
        }
        if (msg.containsKey("releaseYear")) {
            metadataBuilder.setReleaseYear(((Number)msg.get("releaseYear")).intValue());
        }
        if (msg.containsKey("releaseMonth")) {
            metadataBuilder.setReleaseMonth(((Number)msg.get("releaseMonth")).intValue());
        }
        if (msg.containsKey("releaseDay")) {
            metadataBuilder.setReleaseDay(((Number)msg.get("releaseDay")).intValue());
        }
        if (msg.containsKey("artworkData")) {
            metadataBuilder.setArtworkData((byte[])msg.get("artworkData"), PICTURE_TYPE_FRONT_COVER);
        }
        if (msg.containsKey("artworkContentUri")) {
            metadataBuilder.setArtworkUri(Uri.parse((String)msg.get("artworkContentUri")));
        }
        if (msg.containsKey("contentStyle")) {
            final var extras = new Bundle();
            switch ((String)msg.get("contentStyle")) {
                case "list":
                    extras.putInt(MediaConstants.EXTRAS_KEY_CONTENT_STYLE_PLAYABLE, MediaConstants.EXTRAS_VALUE_CONTENT_STYLE_LIST_ITEM);
                    extras.putInt(MediaConstants.EXTRAS_KEY_CONTENT_STYLE_BROWSABLE, MediaConstants.EXTRAS_VALUE_CONTENT_STYLE_LIST_ITEM);
                    break;
                case "grid":
                    extras.putInt(MediaConstants.EXTRAS_KEY_CONTENT_STYLE_PLAYABLE, MediaConstants.EXTRAS_VALUE_CONTENT_STYLE_GRID_ITEM);
                    extras.putInt(MediaConstants.EXTRAS_KEY_CONTENT_STYLE_BROWSABLE, MediaConstants.EXTRAS_VALUE_CONTENT_STYLE_GRID_ITEM);
                    break;
            }
            metadataBuilder.setExtras(extras);
        }

        builder.setMediaMetadata(metadataBuilder.build());
    }
}
