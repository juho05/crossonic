import 'dart:io';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

enum GStreamerStatus { unknown, missing, installed }

class InstallGStreamerViewModel extends ChangeNotifier {
  static const String _gstVersion = "1.26.3";

  GStreamerStatus _status = GStreamerStatus.unknown;
  GStreamerStatus get status => _status;

  bool _downloading = false;
  bool get downloading => _downloading;

  bool _installing = false;
  bool get installing => _installing;

  String? _error;
  String? get error => _error;

  double? _downloadProgress;
  double? get downloadProgress => _downloadProgress;

  bool get supportsAutoInstall => !kIsWeb && Platform.isWindows;

  InstallGStreamerViewModel() {
    if (kIsWeb || !Platform.isWindows) {
      _status = GStreamerStatus.installed;
      return;
    }
    _checkInstalled();
  }

  Future<Result<void>> install() async {
    if (downloading) return const Result.ok(null);
    if (Platform.isWindows) return _installWindows();
    throw UnsupportedError(
        "Installing GStreamer is not supported on this platform");
  }

  Future<Result<void>> _installWindows() async {
    _error = null;

    File? installer;
    try {
      installer = await _downloadInstaller(
          Uri.parse(
              "https://gstreamer.freedesktop.org/data/pkg/windows/$_gstVersion/msvc/gstreamer-1.0-msvc-x86_64-$_gstVersion.msi"),
          "gstreamer-$_gstVersion.msi");

      try {
        _installing = true;
        notifyListeners();
        final result = await Process.run("powershell.exe", [
          "-Command",
          "\$process = Start-Process msiexec.exe -Wait -ArgumentList '/i \"${installer.path}\" /passive' -PassThru; exit \$process.ExitCode"
        ]);
        if (result.exitCode != 0) {
          throw Exception(
              "installer exited with non-zero exit code: ${result.exitCode}");
        }
      } catch (_) {
        _error =
            "Failed to install GStreamer.\nTry to manually install GStreamer Runtime from:\nhttps://gstreamer.freedesktop.org/download/#windows";
        rethrow;
      } finally {
        _installing = false;
      }

      await _checkInstalled();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      _downloadProgress = null;
      try {
        await installer?.delete();
      } catch (e) {
        Log.error("Failed to delete GStreamer installer: $e");
      }
      notifyListeners();
    }
  }

  Future<File> _downloadInstaller(Uri uri, String installerName) async {
    final dir = await getApplicationCacheDirectory();
    final outputFile = File(path.join(dir.path, installerName));
    if (!await outputFile.exists()) {
      IOSink? sink;
      try {
        await outputFile.create(recursive: true);
        sink = outputFile.openWrite();
        _downloading = true;
        notifyListeners();
        final request = http.Request("GET", uri);
        final response = await request.send();
        int downloadedBytes = 0;
        await response.stream.forEach(
          (data) {
            sink!.add(data);
            if (response.contentLength != null) {
              downloadedBytes += data.length;
              _downloadProgress =
                  downloadedBytes / response.contentLength!.toDouble();
              notifyListeners();
            }
          },
        );
        await sink.flush();
      } catch (_) {
        _error =
            "Failed to download GStreamer.\nPlease check your internet connection.";
        rethrow;
      } finally {
        _downloading = false;
        await sink?.close();
      }
    }
    return outputFile;
  }

  Future<void> _checkInstalled() async {
    try {
      final result =
          await Process.run("gst-launch-1.0", ["--version"], runInShell: true);
      if (result.exitCode == 0) {
        _status = GStreamerStatus.installed;
      } else {
        _status = GStreamerStatus.missing;
      }
    } catch (_) {
      _status = GStreamerStatus.missing;
    }
    notifyListeners();
  }
}
