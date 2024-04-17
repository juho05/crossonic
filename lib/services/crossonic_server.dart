import 'dart:convert';

import 'package:crossonic/models/response/crossonic/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CrossonicServer extends ChangeNotifier {
  String? _authToken;
  String? get authToken => _authToken;

  String _serverURL = "";
  String get serverURL => _serverURL;

  Future<bool> connect(String host) async {
    final url = 'http://$host';
    try {
      final response = await http.get(Uri.parse('$url/ping?noAuth=true'));
      if (response.statusCode != 200) return false;
      if (response.body != '"crossonic-success"') return false;
      _serverURL = url;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<(bool, String?)> login(String username, String password) async {
    assert(serverURL != "");
    final response = await http.post(Uri.parse('$serverURL/login'),
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
        headers: {"Content-Type": "application/json"});
    print(response.statusCode);
    if (response.statusCode != 200) return (false, null);
    final auth = LoginResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
    _authToken = auth.authToken;
    notifyListeners();
    return (true, auth.subsonicURL);
  }
}
