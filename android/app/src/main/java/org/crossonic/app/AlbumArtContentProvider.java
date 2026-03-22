/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package org.crossonic.app;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.database.Cursor;
import android.net.Uri;
import android.os.Looper;
import android.os.ParcelFileDescriptor;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

public class AlbumArtContentProvider extends ContentProvider {
    @Override
    public boolean onCreate() {
        CLog.trace("AlbumArtContentProvider", "onCreate called", null);
        return true;
    }

    @Nullable
    @Override
    public ParcelFileDescriptor openFile(@NonNull Uri uri, @NonNull String mode) throws FileNotFoundException {
        final var context = getContext();
        if (context == null) {
            CLog.warn("AlbumArtContentProvider.openFile", "openFile called without context available", null);
            return null;
        }
        if (Looper.myLooper() == Looper.getMainLooper()) {
            CLog.error("AlbumArtContentProvider.openFile", "Called from main thread. Returning null to avoid deadlock.", null);
            return null;
        }
        if (!Objects.equals(uri.getScheme(), "content") ||
                !(Objects.equals(uri.getAuthority(), "org.crossonic.app.covers") || Objects.equals(uri.getAuthority(), "org.crossonic.app.debug.covers"))
                || uri.getPathSegments().size() != 1) {
            CLog.error("AlbumArtContentProvider.openFile", "Received invalid uri: " + uri, null);
            throw new FileNotFoundException();
        }
        final String coverId = uri.getPathSegments().get(0);
        try {
            final var path = (String)FlutterIntegration.invokeMethod("getCoverFile", coverId).get(10, TimeUnit.SECONDS);
            if (path == null) {
                throw new FileNotFoundException();
            }
            CLog.debug("AlbumArtContentProvider.openFile", "Returning cover at: " + path, null);
            return ParcelFileDescriptor.open(new File(path), ParcelFileDescriptor.MODE_READ_ONLY);
        } catch (Exception e) {
            CLog.error("AlbumArtContentProvider.openFile", "Encountered an error while getting cover file from Flutter", e);
            throw new FileNotFoundException();
        }
    }

    @Override
    public int delete(@NonNull Uri uri, @Nullable String selection, @Nullable String[] selectionArgs) {
        CLog.warn("AlbumArtContentProvider.delete", "Called but not implemented", null);
        return 0;
    }

    @Nullable
    @Override
    public String getType(@NonNull Uri uri) {
        CLog.warn("AlbumArtContentProvider.getType", "Called but not implemented", null);
        return "";
    }

    @Nullable
    @Override
    public Uri insert(@NonNull Uri uri, @Nullable ContentValues values) {
        CLog.warn("AlbumArtContentProvider.insert", "Called but not implemented", null);
        return null;
    }

    @Nullable
    @Override
    public Cursor query(@NonNull Uri uri, @Nullable String[] projection, @Nullable String selection, @Nullable String[] selectionArgs, @Nullable String sortOrder) {
        CLog.warn("AlbumArtContentProvider.query", "Called but not implemented", null);
        return null;
    }

    @Override
    public int update(@NonNull Uri uri, @Nullable ContentValues values, @Nullable String selection, @Nullable String[] selectionArgs) {
        CLog.warn("AlbumArtContentProvider.update", "Called but not implemented", null);
        return 0;
    }
}
