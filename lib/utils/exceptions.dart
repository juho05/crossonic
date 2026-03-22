/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() {
    return "AppException: $message";
  }
}

class ConnectionException extends AppException {
  ConnectionException() : super("");

  @override
  String toString() {
    return "ConnectionException";
  }
}

class UnauthenticatedException extends AppException {
  UnauthenticatedException() : super("unauthenticated");

  @override
  String toString() {
    return "UnauthenticatedException";
  }
}

class NotFoundException extends AppException {
  NotFoundException() : super("not found");

  @override
  String toString() {
    return "NotFoundException";
  }
}

class UnexpectedResponseException extends AppException {
  const UnexpectedResponseException(super.message);

  @override
  String toString() {
    return "UnexpectedResponseException: $message";
  }
}

class ServerException implements Exception {
  final int statusCode;
  const ServerException(this.statusCode);
  @override
  String toString() {
    return "ServerException: status code: $statusCode";
  }
}

class CanceledException extends AppException {
  const CanceledException() : super("Operation canceled");

  @override
  String toString() {
    return "Operation canceled";
  }
}
