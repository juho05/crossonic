import 'dart:io';

import 'package:crossonic/utils/exit.dart';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class CrossonicWindowListener with WindowListener, TrayListener {
  CrossonicWindowListener.enable() {
    windowManager.addListener(this);
    if (!kIsWeb && !Platform.isMacOS) {
      windowManager.setPreventClose(true);
      trayManager.addListener(this);
      _initSystemTray();
    }
  }

  Future<void> _updateTrayContextMenu() async {
    if (kIsWeb || Platform.isMacOS) return;
    await trayManager.setContextMenu(Menu(items: [
      if (await windowManager.isVisible())
        MenuItem(
          key: "hide",
          label: "Hide",
        )
      else
        MenuItem(
          key: "show",
          label: "Show",
        ),
      MenuItem.separator(),
      MenuItem(
        key: "exit",
        label: "Exit",
      )
    ]));
  }

  Future<void> _initSystemTray() async {
    await trayManager.setIcon(
        "assets/icon/crossonic-tray.${Platform.isWindows ? "ico" : "png"}");
    if (Platform.isLinux) {
      await trayManager.setTitle("Crossonic");
    } else {
      await trayManager.setToolTip("Crossonic");
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

  @override
  Future<void> onTrayIconMouseDown() async {
    if (await windowManager.isVisible()) {
      await windowManager.hide();
    } else {
      await windowManager.show();
    }
    await _updateTrayContextMenu();
  }

  @override
  Future<void> onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case "show":
        await windowManager.show();
        await _updateTrayContextMenu();
      case "hide":
        await windowManager.hide();
        await _updateTrayContextMenu();
      case "exit":
        await exitApp();
    }
  }
}
