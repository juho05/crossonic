class GitHubRateLimitMaxRetriesExceeded implements Exception {}

class GitHubUnexpectedStatusCode implements Exception {
  final int status;
  GitHubUnexpectedStatusCode(this.status);

  @override
  String toString() {
    return "GitHub: unexpected status code: $status";
  }
}
