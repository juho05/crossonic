import 'dart:io';

import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/repositories/version/version_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class IntegrateAppImageViewModel extends ChangeNotifier {
  static const disabledKey = "integrate_appimage_disabled";

  final KeyValueRepository _keyValue;
  final VersionRepository _versionRepository;

  final _desktopFileDirPath = join(
      Platform.environment["HOME"] ?? "~", ".local", "share", "applications");

  bool _askToIntegrate = false;
  bool get askToIntegrate => _askToIntegrate;

  IntegrateAppImageViewModel({
    required KeyValueRepository keyValue,
    required VersionRepository versionRepository,
  })  : _keyValue = keyValue,
        _versionRepository = versionRepository;

  Future<void> check() async {
    if (kIsWeb ||
        !Platform.isLinux ||
        !Platform.environment.containsKey("APPIMAGE") ||
        Platform.environment["CROSSONIC_DISABLE_APPIMAGE_INTEGRATION"] == "1") {
      return;
    }

    final currentVersion = await _versionRepository.getCurrentVersion();

    final disabled = await _keyValue.loadObject(disabledKey, Version.fromJson);
    if (disabled != null && disabled == currentVersion) {
      Log.debug("AppImage integration is disabled for version $disabled");
      return;
    }

    if (await _isAlreadyIntegrated()) {
      return;
    }

    _askToIntegrate = true;
    notifyListeners();
  }

  void shownDialog() async {
    _askToIntegrate = false;
  }

  Future<void> disable() async {
    _askToIntegrate = false;
    await _keyValue.store(
        disabledKey, await _versionRepository.getCurrentVersion());
    Log.debug("User disabled AppImage integration for version $disable");
  }

  Future<Result<void>> integrate() async {
    _askToIntegrate = false;

    Log.debug("Integrating AppImage into system...");
    try {
      final iconDir = await getApplicationSupportDirectory();

      Log.trace("Copying icon file...");
      final iconBytes =
          await rootBundle.load("assets/icon/desktop/crossonic-512.png");
      await File(join(iconDir.path, "crossonic.png"))
          .writeAsBytes(Uint8List.sublistView(iconBytes));

      final appImageDir =
          join(Platform.environment["HOME"] ?? "~", ".local", "bin");
      final appImagePath = join(appImageDir, "crossonic");

      await Directory(appImageDir).create(recursive: true);
      Log.trace("Moving AppImage...");
      await File(Platform.environment["APPIMAGE"]!).rename(appImagePath);

      try {
        Log.trace("Ensuring AppImage is executable...");
        Process.run("chmod", ["+x", appImagePath]);
      } catch (e, st) {
        Log.warn("Failed to ensure that the integrated AppImage is executable",
            e, st);
      }

      final desktopFile =
          await File(join(_desktopFileDirPath, "org.crossonic.app.desktop"))
              .create(recursive: true);
      Log.trace("Creating desktop file...");
      desktopFile.writeAsString("""[Desktop Entry]
Icon=${join(iconDir.path, "crossonic.png")}
Exec=$appImagePath
Type=Application
Categories=Multimedia
Name=Crossonic
StartupWMClass=org.crossonic.app
Terminal=false
StartupNotify=true
""", flush: true);
    } on Exception catch (e, st) {
      Log.error("Failed to integrate APPIMAGE into desktop environment", e, st);
      return Result.error(e);
    }

    try {
      Log.trace("Updating desktop database...");
      Process.run("update-desktop-database", [_desktopFileDirPath]);
    } catch (e, st) {
      Log.debug(
        "Failed to update desktop database, update-desktop-database is probably not installed",
        e,
        st,
      );
    }

    await _keyValue.remove(disabledKey);

    Log.info("Successfully integrated AppImage into system!");
    return const Result.ok(null);
  }

  Future<bool> _isAlreadyIntegrated() async {
    final actualAppImageFile = File(Platform.environment["APPIMAGE"]!);

    Log.trace("The current AppImage path is: $actualAppImageFile");

    final desiredAppImageFile = File(join(
        Platform.environment["HOME"] ?? "~", ".local", "bin", "crossonic"));

    if (!await actualAppImageFile.exists()) {
      Log.error("APPIMAGE environment variable does not point to a valid file");
      return true;
    }

    if (!await desiredAppImageFile.exists()) {
      Log.debug(
          "AppImage is not integrated because there is no AppImage at the desired system path");
      return false;
    }

    final integrated =
        equals(actualAppImageFile.path, desiredAppImageFile.path);

    if (integrated) {
      Log.debug("AppImage already integrated");
    } else {
      Log.debug(
          "AppImage not integrated because the current AppImage is not at the correct location");
    }

    return integrated;
  }
}
