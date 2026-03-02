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
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public class AlbumArtContentProvider extends ContentProvider {
    @Override
    public boolean onCreate() {
        return true;
    }

    @Nullable
    @Override
    public ParcelFileDescriptor openFile(@NonNull Uri uri, @NonNull String mode) throws FileNotFoundException {
        final var context = getContext();
        if (context == null) return null;
        if (Looper.myLooper() == Looper.getMainLooper()) {
            // TODO handle somehow
            // waiting for flutter response would cause deadlock :(
            return null;
        }
        if (!Objects.equals(uri.getScheme(), "content") ||
                !(Objects.equals(uri.getAuthority(), "org.crossonic.app.covers") || Objects.equals(uri.getAuthority(), "org.crossonic.app.debug.covers"))
                || uri.getPathSegments().size() != 1) {
            throw new FileNotFoundException();
        }
        final String coverId = uri.getPathSegments().get(0);
        try {
            final var path = (String)FlutterIntegration.invokeMethod("getCoverFile", coverId).get(10, TimeUnit.SECONDS);
            if (path == null) {
                throw new FileNotFoundException();
            }
            return ParcelFileDescriptor.open(new File(path), ParcelFileDescriptor.MODE_READ_ONLY);
        } catch (Exception e) {
            throw new FileNotFoundException();
        }
    }

    @Override
    public int delete(@NonNull Uri uri, @Nullable String selection, @Nullable String[] selectionArgs) {
        return 0;
    }

    @Nullable
    @Override
    public String getType(@NonNull Uri uri) {
        return "";
    }

    @Nullable
    @Override
    public Uri insert(@NonNull Uri uri, @Nullable ContentValues values) {
        return null;
    }

    @Nullable
    @Override
    public Cursor query(@NonNull Uri uri, @Nullable String[] projection, @Nullable String selection, @Nullable String[] selectionArgs, @Nullable String sortOrder) {
        return null;
    }

    @Override
    public int update(@NonNull Uri uri, @Nullable ContentValues values, @Nullable String selection, @Nullable String[] selectionArgs) {
        return 0;
    }
}
