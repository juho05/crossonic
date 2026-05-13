/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package org.crossonic.app;

import androidx.annotation.Nullable;
import androidx.media3.common.C;
import androidx.media3.common.ParserException;
import androidx.media3.common.PlaybackException;
import androidx.media3.datasource.DataSourceException;
import androidx.media3.datasource.HttpDataSource;
import androidx.media3.exoplayer.upstream.DefaultLoadErrorHandlingPolicy;
import androidx.media3.exoplayer.upstream.Loader;

import java.io.FileNotFoundException;

import static java.lang.Math.min;

public class CrossonicLoadErrorHandlingPolicy extends DefaultLoadErrorHandlingPolicy {
    @Override
    public int getMinimumLoadableRetryCount(int dataType) {
        return Integer.MAX_VALUE;
    }

    @Override
    public long getRetryDelayMsFor(LoadErrorInfo loadErrorInfo) {
        return isAnyCauseNonRetriable(loadErrorInfo.exception)
                ? C.TIME_UNSET
                : min((loadErrorInfo.errorCount - 1) * 1000, 5000);
    }

    private boolean isAnyCauseNonRetriable(@Nullable Throwable exception) {
        while (exception != null) {
            if (isNonRetriableException(exception)) {
                return true;
            }
            exception = exception.getCause();
        }
        return false;
    }

    private boolean isNonRetriableException(Throwable exception) {
        return exception instanceof ParserException
                || exception instanceof FileNotFoundException
                || exception instanceof HttpDataSource.CleartextNotPermittedException
                || exception instanceof Loader.UnexpectedLoaderException
                || (exception instanceof DataSourceException
                && ((DataSourceException) exception).reason
                == PlaybackException.ERROR_CODE_IO_READ_POSITION_OUT_OF_RANGE);
    }
}
