import 'package:crossonic/data/repositories/version/exception.dart';

class Version implements Comparable {
  final int major;
  final int minor;
  final int patch;

  final bool isFullVersion;

  Version({
    required this.major,
    this.minor = 0,
    this.patch = 0,
    this.isFullVersion = true,
  });

  factory Version.parse(String version) {
    try {
      version = version.trim();
      if (version.startsWith("v") && version.length > 1) {
        version = version.substring(1);
      }
      final parts = version.split("+")[0].split(".");
      if (parts.isEmpty || parts.length > 3) {
        throw InvalidVersion();
      }

      int major = int.parse(parts[0].split("-")[0]);
      if (parts.length == 1) {
        return Version(
          major: major,
          isFullVersion: !parts[0].contains("-"),
        );
      }
      int minor = int.parse(parts[1].split("-")[0]);
      if (parts.length == 2) {
        return Version(
          major: major,
          minor: minor,
          isFullVersion: !parts[1].contains("-"),
        );
      }
      int patch = int.parse(parts[2].split("-")[0]);
      return Version(
        major: major,
        minor: minor,
        patch: patch,
        isFullVersion: !parts[2].contains("-"),
      );
    } catch (_) {
      throw InvalidVersion();
    }
  }

  bool operator >(Version other) {
    if (major > other.major) return true;
    if (major < other.major) return false;
    if (minor > other.minor) return true;
    if (minor < other.minor) return false;
    if (patch > other.patch) return true;
    if (isFullVersion && !other.isFullVersion) return true;
    return false;
  }

  bool operator <(Version other) {
    if (major < other.major) return true;
    if (major > other.major) return false;
    if (minor < other.minor) return true;
    if (minor > other.minor) return false;
    if (patch < other.patch) return true;
    if (!isFullVersion && other.isFullVersion) return true;
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Version) return false;
    return major == other.major &&
        minor == other.minor &&
        patch == other.patch &&
        isFullVersion == other.isFullVersion;
  }

  @override
  int get hashCode => major + minor + patch + isFullVersion.hashCode;

  bool operator >=(Version other) {
    return this > other || this == other;
  }

  bool operator <=(Version other) {
    return this < other || this == other;
  }

  @override
  int compareTo(other) {
    if (this == other) return 0;
    return this < other ? -1 : 1;
  }

  @override
  String toString() {
    final v = "$major.$minor.$patch";
    if (isFullVersion) return v;
    return "$v-prerelease";
  }
}
