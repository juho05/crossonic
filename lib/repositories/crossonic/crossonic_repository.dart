import 'dart:convert';

import 'package:crossonic/exceptions.dart';
import 'package:crossonic/repositories/auth/auth.dart';
import 'package:crossonic/repositories/crossonic/crossonic.dart';
import 'package:http/http.dart' as http;

class CrossonicRepository {
  final AuthRepository _authRepo;
  CrossonicRepository(this._authRepo);

  Future<void> sendNowPlaying(Scrobble? scrobble) async {
    try {
      final auth = await _authRepo.auth;
      final body = jsonEncode({
        "scrobble": scrobble,
      });
      final response = await http.post(
        Uri.parse("${auth.crossonicURL}/nowPlaying"),
        body: body,
        headers: {"Authorization": "Bearer ${auth.authToken}"},
      );
      if (response.statusCode != 200) {
        throw ServerException(response.statusCode);
      }
    } on UnauthenticatedException {
      return;
    }
  }

  Future<void> sendScrobbles(List<Scrobble> scrobbles) async {
    final auth = await _authRepo.auth;
    final response = await http.post(Uri.parse("${auth.crossonicURL}/scrobble"),
        body: jsonEncode({
          "scrobbles": scrobbles,
        }),
        headers: {"Authorization": "Bearer ${auth.authToken}"});
    if (response.statusCode != 200) {
      throw ServerException(response.statusCode);
    }
  }
}
