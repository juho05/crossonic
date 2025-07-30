import 'package:crossonic/data/repositories/themeManager/org_freedesktop_portal_settings.dart';
import 'package:dbus/dbus.dart';

// Original code from
// https://github.com/Merrit/flutter_flatpak/blob/d443e0fcb8f74f844cb39f822a0193ec43e64a4f/lib/src/dbus_interface/dbus_interface.dart

class DBusInterface {
  final _settingsPortal = OrgFreedesktopPortalSettings(
    DBusClient.session(),
    'org.freedesktop.portal.Desktop',
    path: DBusObjectPath('/org/freedesktop/portal/desktop'),
  );

  Future<int?> readThemePreference() async {
    DBusVariant? result;
    try {
      result = await _settingsPortal.callRead(
        'org.freedesktop.appearance',
        'color-scheme',
      ) as DBusVariant;
    } on Exception {
      result = null;
    }

    if (result == null) return null;

    return (result.value as DBusUint32).value;
  }

  Stream<int> get themePreferenceStream => _settingsPortal.settingChanged
      .where((event) => event.key == 'color-scheme')
      .where((event) => event.value.runtimeType == DBusUint32)
      .map((event) => (event.value as DBusUint32).value);
}
