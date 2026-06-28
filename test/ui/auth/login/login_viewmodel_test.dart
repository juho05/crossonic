import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/auth/models/server_features.dart';
import 'package:crossonic/ui/auth/login/login_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

ServerFeatures featuresWithBoth() => ServerFeatures(
      supportsTokenAuth: true,
      supportsPasswordAuth: true,
      apiKeyAuthentication: {1},
    );

ServerFeatures featuresUsernameOnly() => ServerFeatures(
      supportsTokenAuth: true,
      supportsPasswordAuth: false,
    );

ServerFeatures featuresApiKeyOnly() => ServerFeatures(
      apiKeyAuthentication: {1},
    );

ServerFeatures featuresNone() => ServerFeatures();

void main() {
  late MockAuthRepository auth;

  setUp(() {
    auth = MockAuthRepository();
    when(() => auth.serverFeatures).thenReturn(ValueNotifier(featuresWithBoth()));
    when(() => auth.serverUri).thenReturn(Uri.parse('https://music.example.com'));
  });

  LoginViewModel buildViewModel() => LoginViewModel(authRepository: auth);

  group('supportedAuthTypes', () {
    test('contains usernamePassword when token auth supported', () {
      when(() => auth.serverFeatures).thenReturn(ValueNotifier(featuresUsernameOnly()));
      final vm = buildViewModel();
      expect(vm.supportedAuthTypes, contains(AuthType.usernamePassword));
      vm.dispose();
    });

    test('contains apiKey when apiKeyAuthentication contains 1', () {
      when(() => auth.serverFeatures).thenReturn(ValueNotifier(featuresApiKeyOnly()));
      final vm = buildViewModel();
      expect(vm.supportedAuthTypes, contains(AuthType.apiKey));
      vm.dispose();
    });

    test('contains both when both supported', () {
      when(() => auth.serverFeatures).thenReturn(ValueNotifier(featuresWithBoth()));
      final vm = buildViewModel();
      expect(vm.supportedAuthTypes,
          containsAll([AuthType.usernamePassword, AuthType.apiKey]));
      vm.dispose();
    });

    test('empty when nothing supported', () {
      when(() => auth.serverFeatures).thenReturn(ValueNotifier(featuresNone()));
      final vm = buildViewModel();
      expect(vm.supportedAuthTypes, isEmpty);
      vm.dispose();
    });
  });

  group('serverURL', () {
    test('returns host from serverUri', () {
      when(() => auth.serverUri).thenReturn(Uri.parse('https://music.example.com'));
      final vm = buildViewModel();
      expect(vm.serverURL, 'music.example.com');
      vm.dispose();
    });

    test('returns "none" when serverUri is null', () {
      when(() => auth.serverUri).thenReturn(null);
      final vm = buildViewModel();
      expect(vm.serverURL, 'none');
      vm.dispose();
    });
  });

  group('login (apiKey path)', () {
    test('success via apiKey: command completes', () async {
      when(() => auth.loginApiKey(any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();

      await vm.login.execute(LoginData(
        type: AuthType.apiKey,
        username: null,
        password: null,
        apiKey: 'my-api-key',
      ));

      expect(vm.login.completed, isTrue);
      expect(vm.login.error, isFalse);
      verify(() => auth.loginApiKey('my-api-key')).called(1);
      vm.dispose();
    });

    test('error via apiKey: command surfaces error', () async {
      final failure = Exception('bad key');
      when(() => auth.loginApiKey(any()))
          .thenAnswer((_) async => Result.error(failure));
      final vm = buildViewModel();

      await vm.login.execute(LoginData(
        type: AuthType.apiKey,
        username: null,
        password: null,
        apiKey: 'bad-key',
      ));

      expect(vm.login.error, isTrue);
      expect(vm.login.completed, isFalse);
      vm.dispose();
    });
  });

  group('login (usernamePassword path)', () {
    test('success: command completes', () async {
      when(() => auth.loginUsernamePassword(any(), any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();

      await vm.login.execute(LoginData(
        type: AuthType.usernamePassword,
        username: 'user',
        password: 'pass',
        apiKey: null,
      ));

      expect(vm.login.completed, isTrue);
      verify(() => auth.loginUsernamePassword('user', 'pass')).called(1);
      vm.dispose();
    });

    test('error: command surfaces error', () async {
      when(() => auth.loginUsernamePassword(any(), any()))
          .thenAnswer((_) async => Result.error(Exception('wrong password')));
      final vm = buildViewModel();

      await vm.login.execute(LoginData(
        type: AuthType.usernamePassword,
        username: 'user',
        password: 'wrong',
        apiKey: null,
      ));

      expect(vm.login.error, isTrue);
      vm.dispose();
    });
  });

  group('resetServerUri', () {
    test('calls logout(false)', () async {
      when(() => auth.logout(any())).thenAnswer((_) async {});
      final vm = buildViewModel();

      await vm.resetServerUri();

      verify(() => auth.logout(false)).called(1);
      vm.dispose();
    });
  });
}
