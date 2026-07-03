import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

class PermissionHandlerWindowsStub extends PermissionHandlerPlatform {
  static void registerWith() {
    PermissionHandlerPlatform.instance = PermissionHandlerWindowsStub();
  }

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async =>
      PermissionStatus.granted;

  @override
  Future<ServiceStatus> checkServiceStatus(Permission permission) async =>
      ServiceStatus.enabled;

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async =>
      {for (final permission in permissions) permission: PermissionStatus.granted};

  @override
  Future<bool> shouldShowRequestPermissionRationale(
    Permission permission,
  ) async =>
      false;
}