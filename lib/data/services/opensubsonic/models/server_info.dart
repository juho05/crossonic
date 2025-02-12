class ServerInfo {
  final String subsonicVersion;

  final bool isOpenSubsonic;
  final String? serverVersion;
  final String? type;

  final bool isCrossonic;

  ServerInfo({
    required this.serverVersion,
    required this.isOpenSubsonic,
    required this.subsonicVersion,
    required this.type,
    required this.isCrossonic,
  });
}
