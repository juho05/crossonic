import 'dart:async';

import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/logger/log_message.dart';
import 'package:crossonic/data/repositories/logger/log_repository.dart';
import 'package:crossonic/data/repositories/settings/logging.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/services/methodchannel/method_channel_service.dart';
import 'package:crossonic/ui/settings/pages/logs/logs_page_viewmodel.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class MockLogRepository extends Mock implements LogRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockMethodChannelService extends Mock implements MethodChannelService {}

class _FakeKeyValue extends Fake implements KeyValueRepository {
  @override
  Future<void> store<T>(String key, T value) async {}
  @override
  Future<void> remove(String key) async {}
  @override
  Future<String?> loadString(String key) async => null;
  @override
  Future<bool?> loadBool(String key) async => null;
}

LogMessage _msg({
  Level level = Level.info,
  String tag = 'Tag',
  String message = 'msg',
}) =>
    LogMessage(
      sessionStartTime: Log.sessionStartTime,
      time: DateTime(2024, 1, 1),
      level: level,
      tag: tag,
      message: message,
      exception: null,
      stackTrace: '',
    );

void main() {
  setUpAll(() {
    Log.init(MockLogRepository(), MockMethodChannelService());
    registerFallbackValue(DateTime.now());
  });

  late MockLogRepository repo;
  late MockSettingsRepository settings;
  late LoggingSettings logging;
  late StreamController<LogMessage> msgStream;

  setUp(() {
    repo = MockLogRepository();
    settings = MockSettingsRepository();
    msgStream = StreamController<LogMessage>.broadcast();

    when(() => repo.getMessages(any())).thenAnswer((_) async => []);
    when(() => repo.newMessageStream).thenAnswer((_) => msgStream.stream);

    logging = LoggingSettings(keyValueRepository: _FakeKeyValue());
    when(() => settings.logging).thenReturn(logging);
  });

  tearDown(() => msgStream.close());

  LogsPageViewModel build() =>
      LogsPageViewModel(settingsRepository: settings, logRepository: repo);

  // ---- enabledLevels from constructor ----

  group('constructor enabledLevels', () {
    test('warning level -> {warning, error, fatal}', () async {
      logging.level = Level.warning;
      final vm = build();
      expect(vm.enabledLevels, {Level.warning, Level.error, Level.fatal});
      await Future.delayed(Duration.zero);
      vm.dispose();
    });

    test('trace level -> all levels', () async {
      logging.level = Level.trace;
      final vm = build();
      expect(
        vm.enabledLevels,
        {Level.trace, Level.debug, Level.info, Level.warning, Level.error, Level.fatal},
      );
      await Future.delayed(Duration.zero);
      vm.dispose();
    });
  });

  // ---- initial load ----

  group('_loadMessages', () {
    test('logMessages filtered from repo and VM notified', () async {
      final msgs = [_msg(level: Level.info), _msg(level: Level.error)];
      when(() => repo.getMessages(any())).thenAnswer((_) async => msgs);

      var notifications = 0;
      final vm = build();
      vm.addListener(() => notifications++);
      await Future.delayed(Duration.zero);

      expect(vm.logMessages.length, 2);
      expect(notifications, greaterThanOrEqualTo(1));
      vm.dispose();
    });

    test('messages below enabled level are excluded', () async {
      logging.level = Level.warning;
      when(() => repo.getMessages(any())).thenAnswer((_) async => [
            _msg(level: Level.info),
            _msg(level: Level.warning),
            _msg(level: Level.error),
          ]);

      final vm = build();
      await Future.delayed(Duration.zero);

      expect(vm.logMessages.length, 2);
      expect(vm.logMessages.every((m) => m.level >= Level.warning), isTrue);
      vm.dispose();
    });
  });

  // ---- live stream ----

  group('live stream (current session)', () {
    test('enabled-level push appears and notifies', () async {
      final vm = build();
      await Future.delayed(Duration.zero);

      var notifications = 0;
      vm.addListener(() => notifications++);

      msgStream.add(_msg(level: Level.info));
      await Future.delayed(Duration.zero);

      expect(vm.logMessages.length, 1);
      expect(notifications, 1);
      vm.dispose();
    });

    test('disabled-level push is hidden and does not notify', () async {
      logging.level = Level.warning;
      final vm = build();
      await Future.delayed(Duration.zero);

      var notifications = 0;
      vm.addListener(() => notifications++);

      msgStream.add(_msg(level: Level.info));
      await Future.delayed(Duration.zero);

      expect(vm.logMessages, isEmpty);
      expect(notifications, 0);
      vm.dispose();
    });
  });

  // ---- search debounce ----

  group('search', () {
    test('<250ms no filter; at 250ms filters case-insensitively and notifies', () {
      fakeAsync((async) {
        when(() => repo.getMessages(any())).thenAnswer((_) async => [
              _msg(level: Level.info, tag: 'AudioPlayer', message: 'started'),
              _msg(level: Level.info, tag: 'Network', message: 'Connected'),
            ]);
        final vm = build();
        async.flushMicrotasks();

        var notifications = 0;
        vm.addListener(() => notifications++);

        vm.search('audio');
        async.elapse(const Duration(milliseconds: 100));
        expect(notifications, 0);

        async.elapse(const Duration(milliseconds: 200));
        expect(notifications, 1);
        expect(vm.searchText, 'audio');
        expect(vm.logMessages.length, 1);
        expect(vm.logMessages.first.tag, 'AudioPlayer');

        vm.dispose();
      });
    });

    test('rapid calls coalesce to one filter', () {
      fakeAsync((async) {
        when(() => repo.getMessages(any())).thenAnswer((_) async =>
            [_msg(level: Level.info, tag: 'X', message: 'hello')]);
        final vm = build();
        async.flushMicrotasks();

        var notifications = 0;
        vm.addListener(() => notifications++);

        vm.search('a');
        async.elapse(const Duration(milliseconds: 100));
        vm.search('he');
        async.elapse(const Duration(milliseconds: 300));

        expect(notifications, 1);
        expect(vm.searchText, 'he');
        expect(vm.logMessages.length, 1);

        vm.dispose();
      });
    });

    test('empty search shows all enabled messages', () {
      fakeAsync((async) {
        when(() => repo.getMessages(any())).thenAnswer((_) async => [
              _msg(level: Level.info, tag: 'A'),
              _msg(level: Level.info, tag: 'B'),
            ]);
        final vm = build();
        async.flushMicrotasks();

        vm.search('A');
        async.elapse(const Duration(milliseconds: 300));
        expect(vm.logMessages.length, 1);

        vm.search('');
        async.elapse(const Duration(milliseconds: 300));
        expect(vm.logMessages.length, 2);

        vm.dispose();
      });
    });
  });

  // ---- clearSearch ----

  group('clearSearch', () {
    test('resets searchText synchronously, cancels pending debounce, re-filters', () {
      fakeAsync((async) {
        when(() => repo.getMessages(any())).thenAnswer((_) async =>
            [_msg(level: Level.info, tag: 'Hello')]);
        final vm = build();
        async.flushMicrotasks();

        vm.search('xyz');
        async.elapse(const Duration(milliseconds: 100));

        var notifications = 0;
        vm.addListener(() => notifications++);

        vm.clearSearch();

        expect(vm.searchText, '');
        expect(vm.logMessages.length, 1);
        expect(notifications, 1);

        async.elapse(const Duration(milliseconds: 300));
        expect(notifications, 1); // debounce was cancelled

        vm.dispose();
      });
    });
  });

  // ---- enabledLevels setter ----

  group('enabledLevels setter', () {
    test('narrowing re-filters and notifies', () async {
      logging.level = Level.trace;
      when(() => repo.getMessages(any())).thenAnswer((_) async =>
          [_msg(level: Level.info), _msg(level: Level.error)]);
      final vm = build();
      await Future.delayed(Duration.zero);
      expect(vm.logMessages.length, 2);

      var notifications = 0;
      vm.addListener(() => notifications++);

      vm.enabledLevels = {Level.error};

      expect(vm.logMessages.length, 1);
      expect(notifications, 1);
      vm.dispose();
    });
  });

  // ---- changeSessionTime ----

  group('changeSessionTime', () {
    test('same time is a no-op', () async {
      final vm = build();
      await Future.delayed(Duration.zero);
      clearInteractions(repo);

      await vm.changeSessionTime(Log.sessionStartTime);

      verifyNever(() => repo.getMessages(any()));
      vm.dispose();
    });

    test('different time clears, reloads, no live subscription for non-current', () async {
      final otherTime = DateTime(2023, 1, 1);
      final otherMsg = LogMessage(
        sessionStartTime: otherTime,
        time: otherTime,
        level: Level.info,
        tag: 'T',
        message: 'm',
        exception: null,
        stackTrace: '',
      );
      when(() => repo.getMessages(otherTime))
          .thenAnswer((_) async => [otherMsg]);

      final vm = build();
      await Future.delayed(Duration.zero);

      await vm.changeSessionTime(otherTime);

      expect(vm.sessionTime, otherTime);
      expect(vm.logMessages.length, 1);

      var notifications = 0;
      vm.addListener(() => notifications++);

      msgStream.add(_msg(level: Level.info));
      await Future.delayed(Duration.zero);
      expect(notifications, 0);

      vm.dispose();
    });
  });

  // ---- enableMessageStream ----

  group('enableMessageStream', () {
    test('false cancels subscription without notifying', () async {
      final vm = build();
      await Future.delayed(Duration.zero);

      var notifications = 0;
      vm.addListener(() => notifications++);

      await vm.enableMessageStream(false);
      expect(notifications, 0);

      msgStream.add(_msg(level: Level.info));
      await Future.delayed(Duration.zero);
      expect(notifications, 0);

      vm.dispose();
    });

    test('true when already enabled is a no-op (no second getMessages)', () async {
      final vm = build();
      await Future.delayed(Duration.zero);
      clearInteractions(repo);

      await vm.enableMessageStream(true);

      verifyNever(() => repo.getMessages(any()));
      vm.dispose();
    });

    test('non-current session returns early', () async {
      final vm = build();
      await Future.delayed(Duration.zero);

      final otherTime = DateTime(2023, 1, 1);
      when(() => repo.getMessages(otherTime)).thenAnswer((_) async => []);
      await vm.changeSessionTime(otherTime);
      clearInteractions(repo);

      await vm.enableMessageStream(true);

      verifyNever(() => repo.getMessages(any()));
      vm.dispose();
    });
  });

  // ---- dispose ----

  group('dispose', () {
    test('cancels stream subscription so pushes no longer notify', () async {
      final vm = build();
      await Future.delayed(Duration.zero);

      var notifications = 0;
      vm.addListener(() => notifications++);
      vm.dispose();

      msgStream.add(_msg(level: Level.info));
      await Future.delayed(Duration.zero);

      expect(notifications, 0);
    });
  });
}