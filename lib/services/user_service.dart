import 'dart:convert';
import 'dart:typed_data';
import '../models/node_user.dart';
import 'auth_service.dart';
import 'api_service.dart';

class UserService {
  /// GET /users/<uid> → NodeUser
  static Future<NodeUser> fetchUser() async {
    final uid = await AuthService.getUid();
    if (uid == null) throw Exception('Not logged in');
    final res = await ApiService.get('/users/$uid');
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['message'] ?? 'Failed to load user');
    }
    return NodeUser.fromJson(jsonDecode(res.body));
  }

  /// PATCH /users/<uid>  (text fields)
  static Future<NodeUser> updateProfile({
    String? name,
    String? email,
  }) async {
    final uid = await AuthService.getUid();
    if (uid == null) throw Exception('Not logged in');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;

    final res = await ApiService.patch('/users/$uid', body);
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['message'] ?? 'Update failed');
    }
    return NodeUser.fromJson(jsonDecode(res.body));
  }

  /// PATCH /users/<uid>  (avatar upload)
  static Future<NodeUser> uploadAvatar(Uint8List bytes) async {
    final uid = await AuthService.getUid();
    if (uid == null) throw Exception('Not logged in');
    final res = await ApiService.multipartPatch(
      '/users/$uid',
      fileBytes: bytes,
      filename: 'avatar.jpg',
    );
    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['message'] ?? 'Upload failed');
    }
    return NodeUser.fromJson(jsonDecode(res.body));
  }
}