import 'package:dbus/dbus.dart';

// Original code from
// https://github.com/Merrit/flutter_flatpak/blob/d443e0fcb8f74f844cb39f822a0193ec43e64a4f/lib/src/dbus_interface/org_freedesktop_portal_settings.dart

///https://github.com/flatpak/xdg-desktop-portal/blob/main/data/org.freedesktop.portal.Settings.xml

/// org.freedesktop.portal.Settings:
/// @short_description: Settings interface
///
/// This interface provides read-only access to a small number
/// of host settings required for toolkits similar to XSettings.
/// It is not for general purpose settings.
///
/// Currently the interface provides the following keys:
///
/// <variablelist>
///   <varlistentry>
///     <term>org.freedesktop.appearance color-scheme u</term>
///     <listitem><para>
///       Indicates the system's preferred color scheme.
///       Supported values are:
///       <simplelist>
///         <member>0: No preference</member>
///         <member>1: Prefer dark appearance</member>
///         <member>2: Prefer light appearance</member>
///       </simplelist>
///       Unknown values should be treated as 0 (no preference).
///     </para></listitem>
///   </varlistentry>
/// </variablelist>
///
/// Implementations can provide other keys; they are entirely
/// implementation details that are undocumented. If you are a
/// toolkit and want to use this please open an issue.
///
/// This documentation describes version 1 of this interface.

class OrgFreedesktopPortalSettings extends DBusRemoteObject {
  /// Stream of org.freedesktop.portal.Settings.SettingChanged signals.
  late final Stream<OrgFreedesktopPortalSettingsSettingChanged> settingChanged;

  OrgFreedesktopPortalSettings(super.client, String destination,
      {super.path = const DBusObjectPath.unchecked('/')})
      : super(name: destination) {
    settingChanged = DBusRemoteObjectSignalStream(
            object: this,
            interface: 'org.freedesktop.portal.Settings',
            name: 'SettingChanged',
            signature: DBusSignature('ssv'))
        .map((signal) => OrgFreedesktopPortalSettingsSettingChanged(signal));
  }

  /// Gets org.freedesktop.portal.Settings.version
  Future<int> getversion() async {
    var value = await getProperty('org.freedesktop.portal.Settings', 'version',
        signature: DBusSignature('u'));
    return (value as DBusUint32).value;
  }

  /// Invokes org.freedesktop.portal.Settings.ReadAll()
  ///
  /// ReadAll:
  ///     @namespaces: List of namespaces to filter results by, supports simple globbing explained below.
  ///     @value: Dictionary of namespaces to its keys and values.
  ///
  ///     If @namespaces is an empty array or contains an empty string it matches all. Globbing is supported but only for
  ///     trailing sections, e.g. "org.example.*".
  Future<Map<String, Map<String, DBusValue>>> callReadAll(
      List<String> namespaces,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.freedesktop.portal.Settings', 'ReadAll',
        [DBusArray.string(namespaces)],
        replySignature: DBusSignature('a{sa{sv}}'),
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
    return (result.returnValues[0] as DBusDict).children.map((key, value) =>
        MapEntry(
            (key as DBusString).value,
            (value as DBusDict).children.map((key, value) => MapEntry(
                (key as DBusString).value, (value as DBusVariant).value))));
  }

  /// Invokes org.freedesktop.portal.Settings.Read()
  ///
  /// Read:
  ///     @namespace: Namespace to look up @key in.
  ///     @key: The key to get.
  ///     @value: The value @key is set to.
  ///
  ///     Reads a single value. Returns an error on any unknown namespace or key.
  Future<DBusValue> callRead(String namespace, String key,
      {bool noAutoStart = false,
      bool allowInteractiveAuthorization = false}) async {
    var result = await callMethod('org.freedesktop.portal.Settings', 'Read',
        [DBusString(namespace), DBusString(key)],
        replySignature: DBusSignature('v'),
        noAutoStart: noAutoStart,
        allowInteractiveAuthorization: allowInteractiveAuthorization);
    return (result.returnValues[0] as DBusVariant).value;
  }
}

/// Signal data for org.freedesktop.portal.Settings.SettingChanged.
///
/// SettingChanged:
///      @namespace: Namespace of changed setting.
///      @key: The key of changed setting.
///      @value: The new value.
///
///      Emitted when a setting changes.
class OrgFreedesktopPortalSettingsSettingChanged extends DBusSignal {
  String get namespace => (values[0] as DBusString).value;
  String get key => (values[1] as DBusString).value;
  DBusValue get value => (values[2] as DBusVariant).value;

  OrgFreedesktopPortalSettingsSettingChanged(DBusSignal signal)
      : super(
            sender: signal.sender,
            path: signal.path,
            interface: signal.interface,
            name: signal.name,
            values: signal.values);
}
