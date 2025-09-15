import 'dart:io';

import 'package:crossonic/data/repositories/appimage/appimage_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/repositories/version/version_repository.dart';
import 'package:crossonic/data/services/github/exceptions.dart';
import 'package:crossonic/data/services/github/github.dart';
import 'package:crossonic/data/services/updater/updater.dart';
import 'package:crossonic/data/services/updater/updater_android.dart';
import 'package:crossonic/data/services/updater/updater_linux_appimage.dart';
import 'package:crossonic/data/services/updater/updater_windows.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

enum AutoUpdateStatus {
  initial,
  checkingVersion,
  downloading,
  installing,
  success,
  failure
}

class AutoUpdateRepository extends ChangeNotifier {
  final VersionRepository _versionRepository;
  final GitHubService _github;
  final http.Client _http = http.Client();

  static bool get autoUpdatesSupported =>
      !kIsWeb &&
      (Platform.isAndroid ||
          Platform.isWindows ||
          AppImageRepository.isAppImage) &&
      (!const bool.hasEnvironment("VERSION_CHECK") ||
          const bool.fromEnvironment("VERSION_CHECK"));

  late final Updater _updater;

  AutoUpdateStatus _status = AutoUpdateStatus.initial;
  AutoUpdateStatus get status => _status;

  final BehaviorSubject<double> _downloadProgress = BehaviorSubject.seeded(0);
  ValueStream<double> get downloadProgress => _downloadProgress.stream;

  AutoUpdateRepository({
    required VersionRepository versionRepository,
    required GitHubService github,
  })  : _versionRepository = versionRepository,
        _github = github {
    if (Platform.isAndroid) {
      _updater = UpdaterAndroid();
    } else if (Platform.isWindows) {
      _updater = UpdaterWindows();
    } else if (AppImageRepository.isAppImage) {
      _updater = UpdaterLinuxAppImage();
    } else {
      throw UnimplementedError(
          "auto updates are not supported on this platform");
    }
  }

  Future<Result<void>> update() async {
    if (status != AutoUpdateStatus.initial &&
        status != AutoUpdateStatus.failure) {
      Log.warn("Cannot start auto update when it's already running.");
      return const Result.ok(null);
    }

    Log.info("Performing auto update...");

    _status = AutoUpdateStatus.checkingVersion;
    notifyListeners();

    final latestVersionTagResult =
        await _versionRepository.getLatestVersionTag(force: true);
    switch (latestVersionTagResult) {
      case Err():
        _status = AutoUpdateStatus.failure;
        notifyListeners();
        return Result.error(latestVersionTagResult.error);
      case Ok():
    }
    if (latestVersionTagResult.value == null) {
      _status = AutoUpdateStatus.initial;
      notifyListeners();
      return const Result.ok(null);
    }
    final latestVersion = Version.parse(latestVersionTagResult.value!);

    final currentVersion = await VersionRepository.getCurrentVersion();
    if (latestVersionTagResult.value == null ||
        currentVersion >= latestVersion) {
      _status = AutoUpdateStatus.initial;
      notifyListeners();
      return const Result.ok(null);
    }

    final downloadResult = await _download(latestVersionTagResult.value!);
    switch (downloadResult) {
      case Err():
        _status = AutoUpdateStatus.failure;
        notifyListeners();
        return Result.error(downloadResult.error);
      case Ok():
    }

    final file = downloadResult.value;
    Log.debug("Installing ${file.path}...");
    final installResult = await _updater.install(file);

    if (await file.exists()) {
      Log.debug("Removing installer file ${file.path}...");
      await file.delete();
    }

    switch (installResult) {
      case Err():
        _status = AutoUpdateStatus.failure;
        notifyListeners();
        return Result.error(installResult.error);
      case Ok():
    }

    Log.info("Auto update successful!");
    _status = AutoUpdateStatus.success;
    notifyListeners();

    return const Result.ok(null);
  }

  Future<Result<File>> _download(String tag) async {
    final downloadFileName =
        await _updater.generateDownloadFileName(Version.parse(tag));

    final uri = _github.generateReleaseDownloadLink(downloadFileName, tag);

    Log.debug("Downloading $uri...");

    _downloadProgress.add(0);
    _status = AutoUpdateStatus.downloading;
    notifyListeners();

    final targetDir = Directory(path.join(
        (await getTemporaryDirectory()).absolute.path,
        "auto_update_downloads"));

    if (await targetDir.exists()) {
      await targetDir.delete(recursive: true);
    }
    await targetDir.create(recursive: true);

    final request = http.Request("GET", uri);
    request.headers["User-Agent"] =
        "Crossonic v${await VersionRepository.getCurrentVersion()}";

    try {
      final response = await _http.send(request);
      if (response.statusCode != 200) {
        return Result.error(GitHubUnexpectedStatusCode(response.statusCode));
      }

      final totalBytes = (response.contentLength ?? 1).toDouble();

      final outputFile =
          File(path.join(targetDir.path, downloadFileName)).absolute;
      final fileSink = outputFile.openWrite();
      try {
        int downloadedBytes = 0;
        await for (final data in response.stream) {
          fileSink.add(data);
          downloadedBytes += data.length;
          _downloadProgress.add(downloadedBytes / totalBytes);
        }
        await fileSink.flush();
        await fileSink.close();
        return Result.ok(outputFile);
      } on Exception catch (e) {
        await fileSink.close();
        await outputFile.delete(recursive: true);
        return Result.error(e);
      }
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
