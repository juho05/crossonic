import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/version/exception.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/services/github/github.dart';
import 'package:crossonic/utils/result.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionRepository {
  static const _keyLastCheck = "version.last_check";
  static const _keyLatestVersionTag = "version.latest.tag";
  static const _minCheckInterval = Duration(hours: 3);

  static PackageInfo? _packageInfo;

  static Future<Version> getCurrentVersion() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return Version.parse(_packageInfo!.version);
  }

  final GitHubService _github;
  final KeyValueRepository _keyValue;

  VersionRepository({
    required GitHubService github,
    required KeyValueRepository keyValue,
  })  : _github = github,
        _keyValue = keyValue;

  Future<Result<Version?>> getLatestVersion({bool force = false}) async {
    final result = await getLatestVersionTag(force: force);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    if (result.value == null) {
      return const Result.ok(null);
    }
    return Result.ok(Version.parse(result.value!));
  }

  Future<Result<String?>> getLatestVersionTag({bool force = false}) async {
    Log.trace("fetching latest version tag (force refresh: $force)");
    if (!force) {
      final lastCheck = await _keyValue.loadDateTime(_keyLastCheck);
      if (lastCheck != null &&
          DateTime.now().difference(lastCheck) < _minCheckInterval) {
        final latest = await _keyValue.loadString(_keyLatestVersionTag);
        if (latest != null) {
          Log.trace("returning cached version: $latest");
          return Result.ok(latest);
        }
        if (await _keyValue.loadString("version.latest") == null) {
          Log.trace("no cached version available, returning null");
          return const Result.ok(null);
        }
        await _keyValue.remove("version.latest");
      }
    }

    Log.trace("fetching latest version tag from GitHub...");
    final tags = await _github.getRepositoryTags(
        owner: "juho05", repo: "crossonic", pageSize: 30);
    switch (tags) {
      case Err():
        return Result.error(tags.error);
      case Ok():
    }
    List<(String, Version)> versions = [];
    for (final t in tags.value!) {
      try {
        final v = Version.parse(t.name);
        if (!v.isFullVersion) continue;
        if (versions.isNotEmpty && v < versions.last.$2) continue;
        versions.add((t.name, v));
      } on InvalidVersion {
        continue;
      }
    }
    Log.trace("found ${versions.length} valid versions");
    versions.sort((a, b) => b.$2.compareTo(a));
    final latest = versions.firstOrNull;
    Log.debug("Fetched latest version: $latest");

    await _keyValue.store(_keyLastCheck, DateTime.now());
    if (latest != null) {
      Log.trace("storing latest version tag in db: ${latest.$1}");
      await _keyValue.store(_keyLatestVersionTag, latest.$1);
    } else {
      Log.trace("clearing latest version tag in db");
      await _keyValue.remove(_keyLatestVersionTag);
    }

    return Result.ok(latest?.$1);
  }
}
