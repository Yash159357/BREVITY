import 'dart:convert';
import '../models/node_article.dart';
import 'auth_service.dart';
import 'api_service.dart';

class NewsService {
  /// GET /news → list of NodeArticle
  static Future<List<NodeArticle>> fetchNews() async {
    final res = await ApiService.get('/news');
    if (res.statusCode != 200) {
      throw Exception(
          jsonDecode(res.body)['message'] ?? 'Failed to load news');
    }
    final List<dynamic> list = jsonDecode(res.body);
    return list.map((e) => NodeArticle.fromJson(e)).toList();
  }

  /// GET /bookmarks/<uid> → list of NodeArticle
  static Future<List<NodeArticle>> fetchBookmarks() async {
    final uid = await AuthService.getUid();
    if (uid == null) throw Exception('Not logged in');
    final res = await ApiService.get('/bookmarks/$uid');
    if (res.statusCode != 200) {
      throw Exception(
          jsonDecode(res.body)['message'] ?? 'Failed to load bookmarks');
    }
    final List<dynamic> list = jsonDecode(res.body);
    return list.map((e) => NodeArticle.fromJson(e)).toList();
  }

  /// POST /bookmarks  { "userId": uid, "newsId": id }
  static Future<void> addBookmark(String newsId) async {
    final uid = await AuthService.getUid();
    if (uid == null) throw Exception('Not logged in');
    final res = await ApiService.post('/bookmarks', {
      'userId': uid,
      'newsId': newsId,
    });
    if (res.statusCode != 201) {
      throw Exception(
          jsonDecode(res.body)['message'] ?? 'Bookmark failed');
    }
  }

  /// DELETE /bookmarks/<bookmarkId>
  static Future<void> removeBookmark(String bookmarkId) async {
    final res = await ApiService.delete('/bookmarks/$bookmarkId');
    if (res.statusCode != 200) {
      throw Exception(
          jsonDecode(res.body)['message'] ?? 'Remove bookmark failed');
    }
  }
}