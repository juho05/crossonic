/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';

import 'package:crossonic/utils/exit.dart';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class CrossonicWindowListener with WindowListener {
  static CrossonicWindowListener? _instance;

  TrayIcon? _trayIcon;
  Menu? _trayMenu;
  MenuItem? _toggleVisibilityItem;

  CrossonicWindowListener.enable() {
    _instance = this;
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
      if (event is MenuItemClickedEvent) Timer.run(exitApp);
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
    // the linux backend only exposes the menu over dbus with the clicked trigger
    _trayIcon!.setContextMenuTrigger(
      Platform.isLinux
          ? ContextMenuTrigger.clicked
          : ContextMenuTrigger.rightClicked,
    );
    _trayIcon!.addListener((event) {
      if (event is TrayIconClickedEvent) _toggleWindowVisibility();
    });
    _trayIcon!.setVisible(true);

    _trayMenu = menu;
    _toggleVisibilityItem = toggleItem;
    _updateTrayContextMenu();
  }

  static void disposeTray() {
    final instance = _instance;
    final trayIcon = instance?._trayIcon;
    if (instance == null || trayIcon == null) return;
    instance._trayIcon = null;
    trayIcon.setVisible(false);
    trayIcon.dispose();
  }

  Future<void> _updateTrayContextMenu() async {
    if (_trayIcon == null ||
        _trayMenu == null ||
        _toggleVisibilityItem == null) {
      return;
    }
    _toggleVisibilityItem!.label = await windowManager.isVisible()
        ? "Hide"
        : "Show";
    // label changes are not propagated over dbus on linux, setting the menu again forces a layout refresh
    _trayIcon!.setContextMenu(_trayMenu);
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
  Future<void> onWindowEvent(String eventName) async {
    if (eventName == "show" || eventName == "hide") {
      await _updateTrayContextMenu();
    }
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
