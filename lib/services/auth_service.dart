import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/node_user.dart';
import 'api_service.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  /// POST /auth/login  -> NodeUser
  static Future<NodeUser> login(String email, String password) async {
    final res = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['message'] ?? 'Login failed');
    }

    final data = jsonDecode(res.body);
    await _storage.write(key: 'accessToken', value: data['accessToken']);
    await _storage.write(key: 'uid', value: data['user']['_id']);
    return NodeUser.fromJson(data['user']);
  }

  /// POST /auth/register  -> NodeUser
  static Future<NodeUser> register(
      String email, String password, String name) async {
    final res = await ApiService.post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
    });

    if (res.statusCode != 201) {
      throw Exception(jsonDecode(res.body)['message'] ?? 'Registration failed');
    }

    final data = jsonDecode(res.body);
    await _storage.write(key: 'accessToken', value: data['accessToken']);
    await _storage.write(key: 'uid', value: data['user']['_id']);
    return NodeUser.fromJson(data['user']);
  }

  /// helpers
  static Future<String?> getToken() async =>
      _storage.read(key: 'accessToken');

  static Future<String?> getUid() async => _storage.read(key: 'uid');

  static Future<void> logout() async => _storage.deleteAll();
}