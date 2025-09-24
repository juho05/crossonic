import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

class FlutterSecureStorageStub extends FlutterSecureStoragePlatform {
  static void registerWith() {
    FlutterSecureStoragePlatform.instance = FlutterSecureStorageStub();
  }

  @override
  Future<bool> containsKey(
      {required String key, required Map<String, String> options}) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(
      {required String key, required Map<String, String> options}) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) {
    throw UnimplementedError();
  }

  @override
  Future<String?> read(
      {required String key, required Map<String, String> options}) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) {
    throw UnimplementedError();
  }

  @override
  Future<void> write(
      {required String key,
      required String value,
      required Map<String, String> options}) {
    throw UnimplementedError();
  }
}
