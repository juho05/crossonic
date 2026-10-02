import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/auth/models/server_features.dart';
import 'package:crossonic/ui/settings/settings_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_system_integration/flutter_system_integration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockVersionRepository extends Mock implements VersionRepository {}

void main() {
  late MockAuthRepository auth;
  late MockVersionRepository version;

  setUp(() {
    auth = MockAuthRepository();
    version = MockVersionRepository();
  });

  SettingsViewModel buildViewModel() => SettingsViewModel(
        authRepository: auth,
        versionRepository: version,
      );

  test('supportsListenBrainz reflects whether the server is Crossonic', () {
    when(() => auth.serverFeatures)
        .thenReturn(ValueNotifier(ServerFeatures(isCrossonic: true)));

    expect(buildViewModel().supportsListenBrainz, isTrue);
  });

  test('supportsListenBrainz is false for a non-Crossonic server', () {
    when(() => auth.serverFeatures)
        .thenReturn(ValueNotifier(ServerFeatures(isCrossonic: false)));

    expect(buildViewModel().supportsListenBrainz, isFalse);
  });

  group('logout', () {
    test('marks logging out, notifies, and delegates to the repository',
        () async {
      when(() => auth.logout(any())).thenAnswer((_) async {});
      final vm = buildViewModel();
      expect(vm.loggingOut, isFalse);

      var notified = false;
      vm.addListener(() => notified = true);

      await vm.logout();

      expect(vm.loggingOut, isTrue);
      expect(notified, isTrue);
      verify(() => auth.logout(true)).called(1);
    });
  });
}