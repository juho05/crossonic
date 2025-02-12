abstract class SubsonicAuth {
  Map<String, String> get queryParams;
}

class EmptyAuth extends SubsonicAuth {
  @override
  Map<String, String> get queryParams => {};
}

class Connection {
  final Uri baseUri;
  final SubsonicAuth auth;

  const Connection({required this.baseUri, required this.auth});
}
