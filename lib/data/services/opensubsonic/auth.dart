abstract class SubsonicAuth {
  Map<String, String> get queryParams;
  Map<String, String> get queryParamsCacheFriendly => queryParams;
}

class EmptyAuth extends SubsonicAuth {
  @override
  Map<String, String> get queryParams => {};
}

class Connection {
  final Uri baseUri;
  final SubsonicAuth auth;
  final bool supportsPost;

  const Connection(
      {required this.baseUri, required this.auth, required this.supportsPost});
}
