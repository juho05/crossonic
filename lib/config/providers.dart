import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<SingleChildWidget>> get providers async {
  final subsonicService = SubsonicService();

  final authRepository = AuthRepository(
    openSubsonicService: subsonicService,
  );
  await authRepository.loadState();

  return [
    Provider.value(
      value: subsonicService,
    ),
    ChangeNotifierProvider.value(
      value: authRepository,
    ),
    ChangeNotifierProvider(
      create: (context) => FavoritesRepository(
        auth: context.read(),
        subsonic: context.read(),
      ),
    ),
    Provider(
      create: (context) => SubsonicRepository(
        authRepository: context.read(),
        subsonicService: context.read(),
        favoritesRepository: context.read(),
      ),
    ),
  ];
}
