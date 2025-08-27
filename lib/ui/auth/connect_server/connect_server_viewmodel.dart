import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/utils/command.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class InvalidServerException extends AppException {
  InvalidServerException(super.message);
}

class ConnectServerViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  late final Command1<void, Uri> connect;

  String? _serverUrl;
  String? get serverUrl => _serverUrl;

  ConnectServerViewModel({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository {
    connect = Command1(_connect);
    tryCurrentUrlOnWeb();
  }

  Future<void> tryCurrentUrlOnWeb() async {
    if (!kIsWeb) return;
    final u = Uri.base;
    final uri = Uri(
      scheme: u.scheme,
      userInfo: u.userInfo,
      host: u.host,
      port: u.port,
      path: u.path.endsWith("/")
          ? u.path.substring(0, u.path.length - 1)
          : u.path,
    ).toString();
    try {
      final response = await http.get(Uri.parse("$uri/rest/ping"));
      if (response.body.contains("subsonic-response") &&
          (_serverUrl == null || _serverUrl!.isEmpty)) {
        _serverUrl = uri;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<Result<void>> _connect(Uri uri) async {
    uri = Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: uri.host,
      port: uri.port,
      path: uri.path.endsWith("/")
          ? uri.path.substring(0, uri.path.length - 1)
          : uri.path,
    );
    final result = await _authRepository.connect(uri);
    switch (result) {
      case Err():
        Log.error("Failed to connect to server", e: result.error);
        return Result.error(result.error);
      case Ok():
        return const Result.ok(null);
    }
  }

  @override
  void dispose() {
    connect.dispose();
    super.dispose();
  }
}
