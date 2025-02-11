import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

abstract class AuthRepository extends ChangeNotifier {
  bool get hasServer;
  bool get isAuthenticated;

  Future<Result<void>> connect(Uri serverUri);
}
