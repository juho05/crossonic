class LoginResponse {
  final String authToken;
  final String subsonicURL;
  final int expires;
  LoginResponse(this.authToken, this.subsonicURL, this.expires);
  LoginResponse.fromJson(Map<String, dynamic> json)
      : authToken = json['token'] as String,
        subsonicURL = json['subsonicURL'] as String,
        expires = json['expires'] as int;
}
