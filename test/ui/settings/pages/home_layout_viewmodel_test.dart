import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/settings/home_page_layout.dart';
import 'package:crossonic/ui/settings/pages/home_layout_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockKeyValueRepository extends Mock implements KeyValueRepository {
  @override
  Future<void> store<T>(String key, T value) async {}
}

void main() {
  late MockKeyValueRepository keyValue;
  late HomeLayoutSettings settings;

  setUp(() {
    keyValue = MockKeyValueRepository();
    when(() => keyValue.remove(any())).thenAnswer((_) async {});

    settings = HomeLayoutSettings(keyValueRepository: keyValue);
  });

  HomeLayoutViewModel buildViewModel() =>
      HomeLayoutViewModel(settings: settings);

  group('constructor', () {
    test('activeComponents matches selectedOptions on construction', () {
      final vm = buildViewModel();
      expect(vm.activeComponents, settings.selectedOptions.toList());
      vm.dispose();
    });

    test('inactiveComponents is complement in enum declaration order', () {
      final vm = buildViewModel();
      final active = settings.selectedOptions.toSet();
      final expectedInactive = HomeContentOption.values
          .where((o) => !active.contains(o))
          .toList();
      expect(vm.inactiveComponents, expectedInactive);
      vm.dispose();
    });

    test('populates lists from settings on construction', () {
      settings.selectedOptions = [HomeContentOption.favoriteSongs];
      final vm = buildViewModel();
      expect(vm.activeComponents, [HomeContentOption.favoriteSongs]);
      expect(vm.inactiveComponents, isNot(contains(HomeContentOption.favoriteSongs)));
      vm.dispose();
    });
  });

  group('settings change', () {
    test('recomputes both lists and notifies on settings change', () {
      final vm = buildViewModel();
      var notifications = 0;
      vm.addListener(() => notifications++);

      settings.selectedOptions = [HomeContentOption.randomArtists];

      expect(vm.activeComponents, [HomeContentOption.randomArtists]);
      final expectedInactive = HomeContentOption.values
          .where((o) => o != HomeContentOption.randomArtists)
          .toList();
      expect(vm.inactiveComponents, expectedInactive);
      expect(notifications, greaterThanOrEqualTo(1));
      vm.dispose();
    });
  });

  group('remove', () {
    test('remove(i) writes selection without element i', () {
      settings.selectedOptions = [
        HomeContentOption.randomSongs,
        HomeContentOption.randomArtists,
        HomeContentOption.favoriteArtists,
      ];
      final vm = buildViewModel();
      vm.remove(1); // remove randomArtists

      expect(vm.activeComponents, [
        HomeContentOption.randomSongs,
        HomeContentOption.favoriteArtists,
      ]);
      vm.dispose();
    });

    test('removing last active -> empty active list', () {
      settings.selectedOptions = [HomeContentOption.randomSongs];
      final vm = buildViewModel();

      vm.remove(0);

      expect(vm.activeComponents, isEmpty);
      vm.dispose();
    });
  });

  group('reorder', () {
    test('reorder moves item from lower to higher index', () {
      settings.selectedOptions = [
        HomeContentOption.randomSongs,
        HomeContentOption.randomArtists,
        HomeContentOption.favoriteArtists,
      ];
      final vm = buildViewModel();

      vm.reorder(0, 2); // move randomSongs to index 2

      expect(vm.activeComponents, [
        HomeContentOption.randomArtists,
        HomeContentOption.favoriteArtists,
        HomeContentOption.randomSongs,
      ]);
      vm.dispose();
    });

    test('reorder moves item from higher to lower index', () {
      settings.selectedOptions = [
        HomeContentOption.randomSongs,
        HomeContentOption.randomArtists,
        HomeContentOption.favoriteArtists,
      ];
      final vm = buildViewModel();

      vm.reorder(2, 0); // move favoriteArtists to index 0

      expect(vm.activeComponents, [
        HomeContentOption.favoriteArtists,
        HomeContentOption.randomSongs,
        HomeContentOption.randomArtists,
      ]);
      vm.dispose();
    });
  });

  group('add', () {
    test('add(i) appends inactiveComponents[i]', () {
      settings.selectedOptions = [HomeContentOption.randomSongs];
      final vm = buildViewModel();
      final inactiveToAdd = vm.inactiveComponents[0];

      vm.add(0);

      expect(vm.activeComponents.last, inactiveToAdd);
      vm.dispose();
    });
  });
}