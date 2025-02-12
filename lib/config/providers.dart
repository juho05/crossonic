import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<SingleChildWidget>> get providers async {
  final sharedPreferences = SharedPreferencesAsync();
  final secureStorage = FlutterSecureStorage();

  final authRepository = AuthRepository(
    secureStorage: secureStorage,
    sharedPreferences: sharedPreferences,
    openSubsonicService: SubsonicService(),
  );
  await authRepository.loadState();

  return [
    ChangeNotifierProvider(
      create: (context) => authRepository,
    )
  ];
}
