import 'package:crossonic/data/repositories/audio/casting/device.dart';
import 'package:crossonic/data/repositories/audio/casting/device_manager.dart';
import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/ui/casting/casting_viewmodel.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlaybackManager extends Mock implements PlaybackManager {}

class MockPlayerManager extends Mock implements PlayerManager {}

class MockDeviceManager extends Mock implements DeviceManager {}

class FakeDevice extends Device {
  @override
  final String name;
  @override
  final String type;
  @override
  List<String> get extraInfos => const [];
  @override
  IconData get icon => const IconData(0);

  const FakeDevice(this.name, this.type);
}

void main() {
  late MockPlaybackManager playback;
  late MockPlayerManager player;
  late MockDeviceManager deviceManager;

  final local = const FakeDevice('This Phone', 'local');
  final d1 = const FakeDevice('Speaker 1', 'sonos');
  final d2 = const FakeDevice('Speaker 2', 'sonos');

  setUpAll(() {
    registerFallbackValue(const FakeDevice('', ''));
  });

  void setupMocks({
    List<Device>? devices,
    Device? currentDevice,
  }) {
    playback = MockPlaybackManager();
    player = MockPlayerManager();
    deviceManager = MockDeviceManager();

    when(() => playback.player).thenReturn(player);
    when(() => playback.deviceManager).thenReturn(deviceManager);
    when(() => playback.changeDevice(any())).thenAnswer((_) async {});

    when(() => deviceManager.devices).thenReturn(devices ?? [local, d1, d2]);
    when(() => deviceManager.startDiscovery()).thenAnswer((_) async {});
    when(() => deviceManager.stopDiscovery()).thenAnswer((_) async {});

    when(() => player.device).thenReturn(currentDevice ?? local);
  }

  setUp(() => setupMocks());

  CastingViewModel buildViewModel() {
    final vm = CastingViewModel(playbackManager: playback);
    return vm;
  }

  group('construction', () {
    test('seeds currentDevice from player.device', () {
      final vm = buildViewModel();
      expect(vm.currentDevice, local);
    });

    test('seeds discoveredDevices excluding currentDevice', () {
      final vm = buildViewModel();
      expect(vm.discoveredDevices, [d1, d2]);
      expect(vm.discoveredDevices, isNot(contains(local)));
    });

    test('connecting is false initially', () {
      final vm = buildViewModel();
      expect(vm.connecting, isFalse);
    });
  });

  group('_onDevicesChanged via listener', () {
    test('updates discovered and current and notifies', () {
      final vm = buildViewModel();
      final devicesListener =
          verify(() => deviceManager.addListener(captureAny())).captured.last
              as void Function();

      when(() => deviceManager.devices).thenReturn([local, d1]);
      when(() => player.device).thenReturn(local);

      var notified = false;
      vm.addListener(() => notified = true);

      devicesListener();

      expect(vm.discoveredDevices, [d1]);
      expect(vm.currentDevice, local);
      expect(vm.connecting, isFalse);
      expect(notified, isTrue);
    });

    test('resets connecting to false', () async {
      final vm = buildViewModel();
      final devicesListener =
          verify(() => deviceManager.addListener(captureAny())).captured.last
              as void Function();

      when(() => playback.changeDevice(any())).thenAnswer((_) async {
        when(() => player.device).thenReturn(d1);
      });

      await vm.selectDevice(d1);
      expect(vm.connecting, isFalse);

      when(() => deviceManager.devices).thenReturn([local, d1]);
      devicesListener();
      expect(vm.connecting, isFalse);
    });
  });

  group('selectDevice', () {
    test('optimistically sets connecting=true and new currentDevice', () async {
      final vm = buildViewModel();

      final seenConnecting = <bool>[];
      final seenCurrent = <Device?>[];
      vm.addListener(() {
        seenConnecting.add(vm.connecting);
        seenCurrent.add(vm.currentDevice);
      });

      when(() => playback.changeDevice(d1)).thenAnswer((_) async {
        when(() => player.device).thenReturn(d1);
      });

      await vm.selectDevice(d1);

      expect(seenConnecting, contains(true));
      expect(seenCurrent, contains(d1));
    });

    test('prior current is moved to front of discovered list', () async {
      final vm = buildViewModel();

      final seenDiscovered = <List<Device>>[];
      vm.addListener(() => seenDiscovered.add(vm.discoveredDevices.toList()));

      when(() => playback.changeDevice(d1)).thenAnswer((_) async {
        when(() => player.device).thenReturn(d1);
      });

      await vm.selectDevice(d1);

      // During the optimistic update (first notification), local should be first
      final optimisticDiscovered = seenDiscovered.first;
      expect(optimisticDiscovered.first, local);
      expect(optimisticDiscovered, isNot(contains(d1)));
    });

    test('calls changeDevice with selected device', () async {
      final vm = buildViewModel();
      when(() => playback.changeDevice(d1)).thenAnswer((_) async {
        when(() => player.device).thenReturn(d1);
      });

      await vm.selectDevice(d1);

      verify(() => playback.changeDevice(d1)).called(1);
    });

    test('connecting is false after changeDevice + _onDevicesChanged', () async {
      final vm = buildViewModel();
      when(() => playback.changeDevice(d1)).thenAnswer((_) async {
        when(() => player.device).thenReturn(d1);
        when(() => deviceManager.devices).thenReturn([local, d1, d2]);
      });

      await vm.selectDevice(d1);

      expect(vm.connecting, isFalse);
    });

    test('does not rethrow when changeDevice fails', () async {
      final vm = buildViewModel();
      when(() => playback.changeDevice(d1)).thenThrow(Exception('unreachable'));

      await expectLater(vm.selectDevice(d1), completes);
    });

    test('clears connecting when changeDevice fails', () async {
      final vm = buildViewModel();
      when(() => playback.changeDevice(d1)).thenThrow(Exception('unreachable'));

      await vm.selectDevice(d1);

      expect(vm.connecting, isFalse);
    });

    test('reverts currentDevice to actual player device when changeDevice fails',
        () async {
      final vm = buildViewModel();
      when(() => playback.changeDevice(d1)).thenThrow(Exception('unreachable'));

      await vm.selectDevice(d1);

      expect(vm.currentDevice, local);
      expect(vm.discoveredDevices, [d1, d2]);
    });

    test('previously current device reappears in discovered after selecting',
        () async {
      setupMocks(devices: [d1, d2], currentDevice: d1);
      final vm = buildViewModel();
      expect(vm.currentDevice, d1);
      expect(vm.discoveredDevices, [d2]);

      when(() => playback.changeDevice(d2)).thenAnswer((_) async {
        when(() => player.device).thenReturn(d2);
        when(() => deviceManager.devices).thenReturn([d1, d2]);
      });

      await vm.selectDevice(d2);

      expect(vm.currentDevice, d2);
      expect(vm.discoveredDevices, [d1]);
    });
  });

  group('startDiscovery', () {
    test('delegates to deviceManager.startDiscovery', () async {
      final vm = buildViewModel();
      await vm.startDiscovery();
      verify(() => deviceManager.startDiscovery()).called(1);
    });
  });

  group('dispose', () {
    test('calls stopDiscovery and removes listener', () {
      final vm = buildViewModel();
      vm.dispose();
      verify(() => deviceManager.stopDiscovery()).called(1);
      verify(() => deviceManager.removeListener(any())).called(1);
    });
  });
}