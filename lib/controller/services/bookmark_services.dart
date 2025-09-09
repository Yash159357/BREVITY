import 'package:brevity/models/article_model.dart';
import 'package:brevity/utils/api_config.dart';
import 'package:brevity/controller/services/auth_service.dart';
import 'package:brevity/utils/logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

class BookmarkServices {
  static const Duration _httpTimeout = Duration(seconds: 30);
  static const String _bookmarksKey = 'user_bookmarks';
  final AuthService _authService = AuthService();

  /// Save bookmarks to local storage
  Future<void> _saveBookmarksToLocal(List<Article> bookmarks) async {
    Log.i(
      'BOOKMARK_SERVICES: Saving ${bookmarks.length} bookmarks to local storage',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson =
          bookmarks
              .map(
                (article) => {
                  'title': article.title,
                  'description': article.description,
                  'url': article.url,
                  'urlToImage': article.urlToImage,
                  'publishedAt': article.publishedAt.toIso8601String(),
                  'sourceName': article.sourceName,
                  'author': article.author,
                  'content': article.content,
                },
              )
              .toList();
      await prefs.setString(_bookmarksKey, json.encode(bookmarksJson));

      Log.d('BOOKMARK_SERVICES: Successfully saved bookmarks to local storage');
    } catch (e) {
      Log.e('BOOKMARK_SERVICES: Error saving bookmarks to local storage', e);
    }
  }

  /// Load bookmarks from local storage
  Future<List<Article>> _loadBookmarksFromLocal() async {
    Log.d('BOOKMARK_SERVICES: Loading bookmarks from local storage');

    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksString = prefs.getString(_bookmarksKey);

      if (bookmarksString == null || bookmarksString.isEmpty) {
        Log.d('BOOKMARK_SERVICES: No local bookmarks found');
        return [];
      }

      final List<dynamic> bookmarksJson = json.decode(bookmarksString);
      final bookmarks =
          bookmarksJson.map((json) => Article.fromJson(json)).toList();

      Log.d(
        'BOOKMARK_SERVICES: Loaded ${bookmarks.length} bookmarks from local storage',
      );
      return bookmarks;
    } catch (e) {
      Log.e('BOOKMARK_SERVICES: Error loading bookmarks from local storage', e);
      return [];
    }
  }

  /// Get user's bookmarks from backend
  Future<List<Article>> _getBookmarksFromBackend() async {
    Log.i('BOOKMARK_SERVICES: Fetching bookmarks from backend');

    try {
      final token = _authService.accessToken;
      if (token == null) {
        Log.w(
          'BOOKMARK_SERVICES: User not authenticated, cannot fetch from backend',
        );
        throw Exception('User not authenticated');
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.bookmarksUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_httpTimeout);

      Log.d(
        'BOOKMARK_SERVICES: Backend response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final bookmarks = data.map((json) => Article.fromJson(json)).toList();

        Log.i(
          'BOOKMARK_SERVICES: Successfully fetched ${bookmarks.length} bookmarks from backend',
        );

        // Save to local storage for future use
        await _saveBookmarksToLocal(bookmarks);
        return bookmarks;
      } else if (response.statusCode == 404) {
        Log.d('BOOKMARK_SERVICES: No bookmarks found on backend (404)');
        return [];
      } else {
        Log.e(
          'BOOKMARK_SERVICES: Backend fetch failed with status: ${response.statusCode}',
        );
        throw Exception('Failed to fetch bookmarks: ${response.statusCode}');
      }
    } catch (e) {
      Log.e('BOOKMARK_SERVICES: Exception during backend fetch', e);
      return [];
    }
  }

  /// Get bookmarks from local storage immediately (for instant loading)
  Future<List<Article>> getBookmarksFromLocal() async {
    Log.d('BOOKMARK_SERVICES: Getting bookmarks from local storage only');
    return await _loadBookmarksFromLocal();
  }

  /// Get bookmarks instantly from local and sync in background
  /// Returns local data immediately, then syncs with backend
  Future<List<Article>> getBookmarksWithBackgroundSync({
    Function(List<Article>)? onBackendDataLoaded,
  }) async {
    Log.i('BOOKMARK_SERVICES: Getting bookmarks with background sync');

    try {
      // Get local data immediately for instant loading
      final localBookmarks = await _loadBookmarksFromLocal();
      Log.d(
        'BOOKMARK_SERVICES: Returned ${localBookmarks.length} local bookmarks, starting background sync',
      );

      // Sync with backend in background
      _syncWithBackendInBackground(onBackendDataLoaded);

      return localBookmarks;
    } catch (e) {
      Log.e('BOOKMARK_SERVICES: Error getting bookmarks from local', e);
      return [];
    }
  }

  /// Sync with backend in background
  void _syncWithBackendInBackground(Function(List<Article>)? onComplete) async {
    Log.d('BOOKMARK_SERVICES: Starting background sync');

    try {
      final backendBookmarks = await _getBookmarksFromBackendSilent();
      if (backendBookmarks.isNotEmpty) {
        await _saveBookmarksToLocal(backendBookmarks);
        Log.i(
          'BOOKMARK_SERVICES: Background sync completed with ${backendBookmarks.length} bookmarks',
        );
        onComplete?.call(backendBookmarks);
      } else {
        Log.d('BOOKMARK_SERVICES: Background sync completed with no bookmarks');
      }
    } catch (e) {
      Log.e('BOOKMARK_SERVICES: Background sync failed', e);
    }
  }

  /// Get user's bookmarks (fetch from backend and merge with local)
  Future<List<Article>> getBookmarks() async {
    Log.i(
      'BOOKMARK_SERVICES: Getting bookmarks (backend first, local fallback)',
    );

    try {
      // Always fetch from backend first to get latest data
      final backendBookmarks = await _getBookmarksFromBackendSilent();

      if (backendBookmarks.isNotEmpty) {
        // Save the latest backend data to local storage
        await _saveBookmarksToLocal(backendBookmarks);
        Log.d(
          'BOOKMARK_SERVICES: Using backend data (${backendBookmarks.length} bookmarks)',
        );
        return backendBookmarks;
      }

      // If backend fails or returns empty, fallback to local storage
      final localBookmarks = await _loadBookmarksFromLocal();
      Log.d(
        'BOOKMARK_SERVICES: Using local fallback data (${localBookmarks.length} bookmarks)',
      );
      return localBookmarks;
    } catch (e) {
      Log.e(
        'BOOKMARK_SERVICES: Error getting bookmarks, falling back to local',
        e,
      );
      // Fallback to local storage if backend fails
      return await _loadBookmarksFromLocal();
    }
  }

  /// Get bookmarks from backend without throwing errors (silent)
  Future<List<Article>> _getBookmarksFromBackendSilent() async {
    Log.d('BOOKMARK_SERVICES: Silent backend fetch');

    try {
      final token = _authService.accessToken;
      if (token == null) {
        Log.d('BOOKMARK_SERVICES: No auth token for silent fetch');
        return [];
      }

      final response = await http
          .get(
            Uri.parse(ApiConfig.bookmarksUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final bookmarks = data.map((json) => Article.fromJson(json)).toList();
        Log.d(
          'BOOKMARK_SERVICES: Silent fetch successful (${bookmarks.length} bookmarks)',
        );
        return bookmarks;
      } else if (response.statusCode == 404) {
        Log.d('BOOKMARK_SERVICES: Silent fetch - no bookmarks (404)');
        return [];
      } else {
        Log.d(
          'BOOKMARK_SERVICES: Silent fetch failed with status: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      Log.d('BOOKMARK_SERVICES: Silent fetch exception (expected behavior)');
      return [];
    }
  }

  /// Clear local bookmarks cache (useful for logout)
  Future<void> clearLocalBookmarks() async {
    Log.i('BOOKMARK_SERVICES: Clearing local bookmarks cache');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bookmarksKey);
      Log.d('BOOKMARK_SERVICES: Local bookmarks cache cleared successfully');
    } catch (e) {
      Log.e('BOOKMARK_SERVICES: Error clearing local bookmarks', e);
    }
  }

  /// Force refresh bookmarks from backend (useful for sync)
  Future<List<Article>> refreshBookmarksFromBackend() async {
    Log.i('BOOKMARK_SERVICES: Force refreshing bookmarks from backend');

    try {
      // Clear local cache first
      await clearLocalBookmarks();
      // Fetch fresh data from backend
      final refreshedBookmarks = await _getBookmarksFromBackend();
      Log.i(
        'BOOKMARK_SERVICES: Force refresh completed (${refreshedBookmarks.length} bookmarks)',
      );
      return refreshedBookmarks;
    } catch (e) {
      Log.e('BOOKMARK_SERVICES: Error refreshing bookmarks from backend', e);
      return [];
    }
  }

  /// Toggle bookmark status on backend and update local storage
  Future<void> toggleBookmark(Article article) async {
    Log.i('BOOKMARK_SERVICES: Toggling bookmark for article: ${article.title}');

    try {
      final token = _authService.accessToken;
      if (token == null) {
        Log.w('BOOKMARK_SERVICES: User not authenticated for bookmark toggle');
        throw Exception('User not authenticated');
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.bookmarksUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'title': article.title,
              'description': article.description,
              'url': article.url,
              'urlToImage': article.urlToImage,
              'publishedAt': article.publishedAt.toIso8601String(),
              'sourceName': article.sourceName,
              'author': article.author,
              'content': article.content,
            }),
          )
          .timeout(_httpTimeout);

      Log.d(
        'BOOKMARK_SERVICES: Bookmark toggle response status: ${response.statusCode}',
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        Log.e(
          'BOOKMARK_SERVICES: Bookmark toggle failed with status: ${response.statusCode}',
        );
        throw Exception('Failed to toggle bookmark: ${response.statusCode}');
      }

      // Update local storage after successful backend operation
      await _updateLocalBookmarks(article);

      final NotificationService notificationService = NotificationService();
      await notificationService.updateBookmarkReminder();

      Log.i('BOOKMARK_SERVICES: Bookmark toggle completed successfully');
    } catch (e) {
      Log.e('BOOKMARK_SERVICES: Exception during bookmark toggle', e);
      rethrow;
    }
  }

  /// Update local bookmarks after toggle
  Future<void> _updateLocalBookmarks(Article article) async {
    Log.d('BOOKMARK_SERVICES: Updating local bookmarks after toggle');

    try {
      final localBookmarks = await _loadBookmarksFromLocal();
      final existingIndex = localBookmarks.indexWhere(
        (a) => a.url == article.url,
      );

      if (existingIndex >= 0) {
        // Remove if already bookmarked
        localBookmarks.removeAt(existingIndex);
        Log.d('BOOKMARK_SERVICES: Removed bookmark from local storage');
      } else {
        // Add if not bookmarked
        localBookmarks.add(article);
        Log.d('BOOKMARK_SERVICES: Added bookmark to local storage');
      }

      await _saveBookmarksToLocal(localBookmarks);
    } catch (e) {
      Log.e('BOOKMARK_SERVICES: Error updating local bookmarks', e);
    }
  }

  /// Check if article is bookmarked (check latest data)
  Future<bool> isBookmarked(String url) async {
    Log.d('BOOKMARK_SERVICES: Checking if article is bookmarked: $url');

    try {
      // Get the latest bookmarks (which fetches from backend first)
      final bookmarks = await getBookmarks();
      final isBookmarked = bookmarks.any((a) => a.url == url);

      Log.d('BOOKMARK_SERVICES: Bookmark check result for $url: $isBookmarked');
      return isBookmarked;
    } catch (e) {
      Log.e(
        'BOOKMARK_SERVICES: Error checking bookmark status, falling back to local',
        e,
      );
      // Fallback to local storage if backend fails
      final localBookmarks = await _loadBookmarksFromLocal();
      final isBookmarked = localBookmarks.any((a) => a.url == url);

      Log.d(
        'BOOKMARK_SERVICES: Local bookmark check result for $url: $isBookmarked',
      );
      return isBookmarked;
    }
  }
}
