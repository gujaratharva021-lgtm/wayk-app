import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../services/alarm_poller.dart';
import '../services/notification_service.dart';

/// Holds the logged-in user's JWT token and basic profile info, persisted
/// to SharedPreferences so the session survives app restarts. Every other
/// screen reads `isLoggedIn` / `token` from this via Provider.
class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _userName;
  bool _loading = true;

  String? get token => _token;
  String? get userName => _userName;
  bool get isLoggedIn => _token != null;
  bool get loading => _loading;

  AuthProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userName = prefs.getString('user_name');
    _loading = false;
    notifyListeners();
    if (_token != null) AlarmPoller.start();
  }

  /// Returns null on success, or an error message to show the user.
  Future<String?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['token'] != null) {
        await _saveSession(data['token'], data['user']?['name'] ?? '');
        return null;
      }
      return data['error']?.toString() ?? 'Login failed';
    } catch (e) {
      return 'Could not reach server. Is the backend running?';
    }
  }

  /// Returns null on success, or an error message to show the user.
  Future<String?> register(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      final data = jsonDecode(res.body);

      if (res.statusCode == 201 && data['token'] != null) {
        await _saveSession(data['token'], name);
        return null;
      }
      return data['error']?.toString() ?? 'Registration failed';
    } catch (e) {
      return 'Could not reach server. Is the backend running?';
    }
  }

  Future<void> _saveSession(String token, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user_name', name);
    _token = token;
    _userName = name;
    notifyListeners();
    AlarmPoller.start();
    NotificationService.show('Welcome', 'Hi $name, glad to see you on OneX.');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_name');
    _token = null;
    _userName = null;
    notifyListeners();
  }
}
