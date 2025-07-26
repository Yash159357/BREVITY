import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  // Change this if your Node backend is on another host/port
  static const String _baseUrl = 'http://localhost:8000';

  /// Generic headers with optional JWT
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /* ---------- JSON helpers ---------- */

  static Future<http.Response> get(String endpoint) async =>
      http.get(Uri.parse('$_baseUrl$endpoint'), headers: await _headers());

  static Future<http.Response> post(
      String endpoint, Map<String, dynamic> body) async {
    return http.post(Uri.parse('$_baseUrl$endpoint'),
        headers: await _headers(), body: jsonEncode(body));
  }

  static Future<http.Response> patch(
      String endpoint, Map<String, dynamic> body) async {
    return http.patch(Uri.parse('$_baseUrl$endpoint'),
        headers: await _headers(), body: jsonEncode(body));
  }

  static Future<http.Response> delete(String endpoint) async =>
      http.delete(Uri.parse('$_baseUrl$endpoint'), headers: await _headers());

  /* ---------- Multipart (avatar upload) ---------- */

  /// PATCH with multipart/form-data
  static Future<http.Response> multipartPatch(
    String endpoint, {
    Map<String, String> fields = const {},
    required Uint8List fileBytes,
    String fileField = 'profileImage',
    String filename = 'avatar.jpg',
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('$_baseUrl$endpoint');

    final request = http.MultipartRequest('PATCH', uri)
      ..headers.addAll(await _headers())
      ..fields.addAll(fields)
      ..files.add(http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: filename,
      ));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    return await http.Response.fromStream(await request.send());
  }
}