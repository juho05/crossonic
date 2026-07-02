import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/ui/auth/connect_server/connect_server_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  late MockAuthRepository auth;

  setUp(() {
    auth = MockAuthRepository();
  });

  ConnectServerViewModel buildViewModel() =>
      ConnectServerViewModel(authRepository: auth);

  group('connect', () {
    test('completes successfully when the repository connects', () async {
      when(() => auth.connect(any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();

      await vm.connect.execute(Uri.parse('https://music.example.com'));

      expect(vm.connect.completed, isTrue);
      expect(vm.connect.error, isFalse);
      expect(vm.connect.running, isFalse);
    });

    test('surfaces the error when the repository fails to connect', () async {
      final failure = Exception('unreachable');
      when(() => auth.connect(any()))
          .thenAnswer((_) async => Result.error(failure));
      final vm = buildViewModel();

      await vm.connect.execute(Uri.parse('https://music.example.com'));

      expect(vm.connect.error, isTrue);
      expect(vm.connect.completed, isFalse);
      expect((vm.connect.result as Err).error, same(failure));
    });

    test('strips a trailing slash from the path before connecting', () async {
      when(() => auth.connect(any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();

      await vm.connect.execute(Uri.parse('https://music.example.com/sub/'));

      final captured =
          verify(() => auth.connect(captureAny())).captured.single as Uri;
      expect(captured.path, '/sub');
    });

    test('leaves a path without a trailing slash untouched', () async {
      when(() => auth.connect(any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();

      await vm.connect.execute(Uri.parse('https://music.example.com/sub'));

      final captured =
          verify(() => auth.connect(captureAny())).captured.single as Uri;
      expect(captured.path, '/sub');
    });

    test('strips the trailing slash from a root path', () async {
      when(() => auth.connect(any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();

      await vm.connect.execute(Uri.parse('https://music.example.com/'));

      final captured =
          verify(() => auth.connect(captureAny())).captured.single as Uri;
      expect(captured.path, isEmpty);
    });

    test('preserves scheme, host and port while normalizing the path',
        () async {
      when(() => auth.connect(any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();

      await vm.connect
          .execute(Uri.parse('https://music.example.com:8080/sub/'));

      final captured =
          verify(() => auth.connect(captureAny())).captured.single as Uri;
      expect(captured.scheme, 'https');
      expect(captured.host, 'music.example.com');
      expect(captured.port, 8080);
      expect(captured.path, '/sub');
    });
  });
}
