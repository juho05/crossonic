/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package org.crossonic.app;

import androidx.media3.common.ForwardingSimpleBasePlayer;
import androidx.media3.common.Player;
import androidx.media3.common.util.UnstableApi;

@UnstableApi
public class ChangePlayer extends ForwardingSimpleBasePlayer {
    private final Player androidPlayer;
    private final Player flutterPlayer;

    Player activePlayer;

    public ChangePlayer(Player androidPlayer, Player flutterPlayer) {
        super(androidPlayer);
        this.androidPlayer = androidPlayer;
        this.flutterPlayer = flutterPlayer;
        this.activePlayer = androidPlayer;
    }

    public void disableAndroid() {
        if (activePlayer != androidPlayer) return;

        activePlayer = flutterPlayer;
        setPlayer(flutterPlayer);
        activePlayer.stop();
        CLog.debug("ChangePlayer", "flutter player active", null);
    }

    public void enableAndroid() {
        if (activePlayer == androidPlayer) return;
        activePlayer = androidPlayer;
        setPlayer(androidPlayer);
        CLog.debug("ChangePlayer", "android player active", null);
    }
}
