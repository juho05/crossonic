import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/version/exception.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/services/github/github.dart';
import 'package:crossonic/utils/result.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionRepository {
  static const _keyLastCheck = "version.last_check";
  static const _keyLatestVersion = "version.latest";
  static const _minCheckInterval = Duration(hours: 3);

  final GitHubService _github;
  final KeyValueRepository _keyValue;

  PackageInfo? _packageInfo;

  VersionRepository({
    required GitHubService github,
    required KeyValueRepository keyValue,
  })  : _github = github,
        _keyValue = keyValue;

  Future<Result<Version?>> getLatestVersion({bool force = false}) async {
    if (!force) {
      final lastCheck = await _keyValue.loadDateTime(_keyLastCheck);
      if (lastCheck != null &&
          DateTime.now().difference(lastCheck) < _minCheckInterval) {
        final latest = await _keyValue.loadString(_keyLatestVersion);
        if (latest == null) return Result.ok(null);
        return Result.ok(Version.parse(latest));
      }
    }

    final tags = await _github.getRepositoryTags(
        owner: "juho05", repo: "crossonic", pageSize: 30);
    switch (tags) {
      case Err():
        return Result.error(tags.error);
      case Ok():
    }
    List<Version> versions = [];
    for (final t in tags.value!) {
      try {
        final v = Version.parse(t.name);
        if (!v.isFullVersion) continue;
        if (versions.isNotEmpty && v < versions.last) continue;
        versions.add(v);
      } on InvalidVersion {
        continue;
      }
    }
    versions.sort((a, b) => b.compareTo(a));
    final latest = versions.firstOrNull;
    Log.trace("Fetched latest version: $latest");

    await _keyValue.store(_keyLastCheck, DateTime.now());
    if (latest != null) {
      await _keyValue.store(_keyLatestVersion, latest.toString());
    } else {
      await _keyValue.remove(_keyLatestVersion);
    }

    return Result.ok(latest);
  }

  Future<Version> getCurrentVersion() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return Version.parse(_packageInfo!.version);
  }
}
