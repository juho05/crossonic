/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:crossonic/utils/exit.dart';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class CrossonicWindowListener with WindowListener {
  TrayIcon? _trayIcon;
  MenuItem? _toggleVisibilityItem;

  CrossonicWindowListener.enable() {
    windowManager.addListener(this);
    if (!kIsWeb && !Platform.isMacOS) {
      windowManager.setPreventClose(true);
      _initSystemTray();
    }
  }

  void _initSystemTray() {
    if (_trayIcon != null) return;
    _trayIcon = TrayIcon.create();
    final menu = Menu.create();
    final toggleItem = MenuItem.createWithLabelAndType(
      "Hide",
      MenuItemType.normal,
    );
    final exitItem = MenuItem.createWithLabelAndType(
      "Exit",
      MenuItemType.normal,
    );
    if (_trayIcon == null ||
        menu == null ||
        toggleItem == null ||
        exitItem == null) {
      return;
    }

    toggleItem.addListener((event) {
      if (event is MenuItemClickedEvent) _toggleWindowVisibility();
    });
    exitItem.addListener((event) {
      if (event is MenuItemClickedEvent) exitApp();
    });
    menu.addItem(toggleItem);
    menu.addSeparator();
    menu.addItem(exitItem);

    _trayIcon!.icon = ImageAsset.fromAsset(
      "assets/icon/crossonic-tray.${Platform.isWindows ? "ico" : "png"}",
    );
    _trayIcon!.setTooltip("Crossonic");
    if (Platform.isLinux) {
      _trayIcon!.setTitle("Crossonic");
    }
    _trayIcon!.setContextMenu(menu);
    _trayIcon!.setContextMenuTrigger(ContextMenuTrigger.rightClicked);
    _trayIcon!.addListener((event) {
      if (event is TrayIconClickedEvent) _toggleWindowVisibility();
    });
    _trayIcon!.setVisible(true);

    _toggleVisibilityItem = toggleItem;
    _updateTrayContextMenu();
  }

  Future<void> _updateTrayContextMenu() async {
    if (_toggleVisibilityItem == null) return;
    _toggleVisibilityItem!.label = await windowManager.isVisible() ? "Hide" : "Show";
  }

  Future<void> _toggleWindowVisibility() async {
    if (await windowManager.isVisible()) {
      await windowManager.hide();
    } else {
      await windowManager.show();
    }
    await _updateTrayContextMenu();
  }

  @override
  Future<void> onWindowFocus() async {
    await _updateTrayContextMenu();
  }

  @override
  Future<void> onWindowClose() async {
    if (!kIsWeb && Platform.isMacOS) {
      super.onWindowClose();
      return;
    }
    await windowManager.hide();
    await _updateTrayContextMenu();
  }
}
