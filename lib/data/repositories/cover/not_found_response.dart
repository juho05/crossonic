import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class NotFoundResponse extends FileServiceResponse {
  @override
  Stream<List<int>> get content => const Stream.empty();

  @override
  int? get contentLength => 0;

  @override
  String? get eTag => null;

  @override
  String get fileExtension => ".file";

  @override
  int get statusCode => 404;

  @override
  DateTime get validTill => DateTime.now();
}
