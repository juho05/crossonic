class ServerUnreachableException implements Exception {}

class UnauthenticatedException implements Exception {}

class InvalidStateException implements Exception {
  final String message;
  const InvalidStateException(this.message);
  @override
  String toString() {
    return "InvalidStateException: $message";
  }
}

class UnexpectedServerResponseException implements Exception {}

class ServerException implements Exception {
  final int statusCode;
  const ServerException(this.statusCode);
  @override
  String toString() {
    return "ServerException: status code: $statusCode";
  }
}

class InvalidCredentialsException implements Exception {}
