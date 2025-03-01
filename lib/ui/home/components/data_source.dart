import 'package:crossonic/utils/result.dart';

abstract interface class HomeComponentDataSource<T> {
  Future<Result<Iterable<T>>> get(int count);
}
