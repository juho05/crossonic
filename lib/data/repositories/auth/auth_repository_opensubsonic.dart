import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/utils/result.dart';

class AuthRepositoryOpenSubsonic extends AuthRepository {
  @override
  Future<Result<void>> connect(Uri serverUri) async {
    return Result.ok(null);
  }

  @override
  bool get hasServer => false;

  @override
  bool get isAuthenticated => false;
}
