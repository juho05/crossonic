import 'dart:io';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

enum GStreamerStatus { unknown, missing, installed }

class InstallGStreamerViewModel extends ChangeNotifier {
  static const String _gstVersion = "1.26.1";

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

  InstallGStreamerViewModel() {
    if (kIsWeb || (!Platform.isWindows /*&& !Platform.isMacOS*/)) {
      _status = GStreamerStatus.installed;
      return;
    }
    _checkInstalled();
  }

  Future<Result<void>> install() async {
    if (downloading) return Result.ok(null);
    if (Platform.isWindows) return _installWindows();
    //if (Platform.isMacOS) return _installMacOS();
    throw UnsupportedError(
        "Installing GStreamer is not supported on this platform");
  }

  Future<Result<void>> _installWindows() async {
    final dir = await getApplicationCacheDirectory();
    final outputFile = File(path.join(dir.path, "gstreamer-$_gstVersion.msi"));

    _error = null;

    IOSink? sink;
    try {
      if (!await outputFile.exists()) {
        try {
          await outputFile.create(recursive: true);
          sink = outputFile.openWrite();
          _downloading = true;
          notifyListeners();
          final request = http.Request(
              "GET",
              Uri.parse(
                  "https://gstreamer.freedesktop.org/data/pkg/windows/1.26.1/msvc/gstreamer-1.0-msvc-x86_64-$_gstVersion.msi"));
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

      try {
        _installing = true;
        notifyListeners();
        final result = await Process.run("powershell.exe", [
          "-Command",
          "\$process = Start-Process msiexec.exe -Wait -ArgumentList '/i \"${outputFile.path}\" /passive' -PassThru; exit \$process.ExitCode"
        ]);
        if (result.exitCode != 0) {
          throw Exception(
              "installer exited with non-zero exit code: ${result.exitCode}");
        }
      } catch (_) {
        _error =
            "Failed to install GStreamer.\nTry to manually install GStreamer from:\nhttps://gstreamer.freedesktop.org/download/#windows";
        rethrow;
      } finally {
        _installing = false;
      }

      await _checkInstalled();
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      _downloadProgress = null;
      try {
        await outputFile.delete();
      } catch (e) {
        Log.error("Failed to delete GStreamer installer: $e");
      }
      notifyListeners();
    }
  }

  // Future<Result<void>> _installMacOS() async {
  //   final dir = await getApplicationCacheDirectory();
  //   // https://gstreamer.freedesktop.org/data/pkg/osx/1.26.1/gstreamer-1.0-$_gstVersion-universal.pkg
  //   // installer -pkg /path/to/gstreamer.pkg -target /
  //   return Result.ok(null);
  // }

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
