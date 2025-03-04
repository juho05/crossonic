import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

class CoverFileService extends FileService {
  final http.Client _httpClient;
  final SubsonicService _subsonic;
  final AuthRepository _auth;

  CoverFileService(
      {required SubsonicService subsonicService,
      required AuthRepository authRepository,
      http.Client? httpClient})
      : _subsonic = subsonicService,
        _auth = authRepository,
        _httpClient = httpClient ?? http.Client();

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String>? headers}) async {
    final parts = url.split("\t");
    final u = parts[0];
    final s = parts.elementAtOrNull(1);
    final coverUrl = _subsonic.getCoverUri(
      _auth.con,
      u,
      size: s != null ? int.parse(s) : null,
    );
    final req = http.Request('GET', coverUrl);
    if (headers != null) {
      req.headers.addAll(headers);
    }
    final httpResponse = await _httpClient.send(req);

    return HttpGetResponse(httpResponse);
  }
}
