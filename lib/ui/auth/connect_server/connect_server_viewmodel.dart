import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/utils/command.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';

class InvalidServerException extends AppException {
  InvalidServerException(super.message);
}

class ConnectServerViewModel {
  final AuthRepository _authRepository;

  late final Command1<void, Uri> connect;

  ConnectServerViewModel({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository {
    connect = Command1(_connect);
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
        return Result.error(result.error);
      case Ok():
        return Result.ok(null);
    }
  }
}
