import 'package:brevity/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:brevity/models/article_model.dart';
import 'package:brevity/utils/api_config.dart';

// Custom exception classes for better error handling
class NewsServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String? category;
  
  NewsServiceException(this.message, {this.statusCode, this.category});
  
  @override
  String toString() => 'NewsServiceException: $message';
}

class NetworkException extends NewsServiceException {
  NetworkException(super.message) : super(category: 'network');
}

class ServerException extends NewsServiceException {
  ServerException(super.message, int statusCode) 
    : super(statusCode: statusCode, category: 'server');
}

// Cache response model
class CachedResponse {
  final List<Article> articles;
  final DateTime timestamp;
  
  CachedResponse(this.articles, this.timestamp);
  
  bool get isExpired => 
    DateTime.now().difference(timestamp) > const Duration(minutes: 10);
}

class NewsService {
  // Singleton pattern
  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;
  NewsService._internal();

  // HTTP client with custom configuration
  http.Client? _httpClient;
  bool _isInitialized = false;
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  
  // Cache configuration
  final Map<String, CachedResponse> _cache = {};
  
  // Pagination configuration
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;
  static const int minPageSize = 1;
  
  // Initialize the service
  Future<void> initialize() async {
    _httpClient = http.Client();
    _isInitialized = true;
  }
  
  // Dispose method to clean up resources
  void dispose() {
    _httpClient?.close();
    _httpClient = null;
    _isInitialized = false;
    _cache.clear();
  }
  
  // Validate pagination parameters
  Map<String, int> _validatePaginationParams({required int page, required int pageSize}) {
    final validatedPage = page < 1 ? 1 : page;
    final validatedPageSize = pageSize < minPageSize 
        ? defaultPageSize 
        : pageSize > maxPageSize 
            ? maxPageSize 
            : pageSize;
    
    return {
      'page': validatedPage,
      'pageSize': validatedPageSize,
    };
  }
  
  // Get authentication headers if available
  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
  
  // Generic method to make HTTP requests with retry logic
  Future<http.Response> _makeRequest(String url) async {
    if (_httpClient == null) {
      await initialize();
    }
    
    int retryCount = 0;
    
    while (retryCount < _maxRetries) {
      try {
        final headers = await _getHeaders();
        final response = await _httpClient!
            .get(Uri.parse(url), headers: headers)
            .timeout(_timeout);
        
        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode >= 500 && retryCount < _maxRetries - 1) {
          // Retry on server errors
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount * 2));
          continue;
        } else {
          throw ServerException(
            'Server error: ${response.statusCode}', 
            response.statusCode
          );
        }
      } catch (e) {
        if (e is TimeoutException) {
          if (retryCount < _maxRetries - 1) {
            retryCount++;
            await Future.delayed(Duration(seconds: retryCount * 2));
            continue;
          } else {
            throw NetworkException('Request timed out after $_maxRetries attempts');
          }
        } else if (e is NewsServiceException) {
          rethrow;
        } else {
          throw NetworkException('Network error: $e');
        }
      }
    }
    
    throw NetworkException('Failed after $_maxRetries attempts');
  }
  
  // Check cache for cached response
  List<Article>? _getCachedResponse(String cacheKey) {
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.articles;
    } else if (cached != null && cached.isExpired) {
      _cache.remove(cacheKey);
    }
    return null;
  }
  
  // Cache response
  void _cacheResponse(String cacheKey, List<Article> articles) {
    _cache[cacheKey] = CachedResponse(articles, DateTime.now());
  }

  // Fetch trending news
  Future<List<Article>> fetchTrendingNews({int page = 1, int pageSize = 10}) async {
    final params = _validatePaginationParams(page: page, pageSize: pageSize);
    return _fetchNewsByCategory('general', page: params['page']!, pageSize: params['pageSize']!);
  }

  // Fetch Technology news
  Future<List<Article>> fetchTechnologyNews({int page = 1, int pageSize = 10}) async {
    final params = _validatePaginationParams(page: page, pageSize: pageSize);
    return _fetchNewsByCategory('technology', page: params['page']!, pageSize: params['pageSize']!);
  }

  // Fetch Sports news
  Future<List<Article>> fetchSportsNews({int page = 1, int pageSize = 10}) async {
    final params = _validatePaginationParams(page: page, pageSize: pageSize);
    return _fetchNewsByCategory('sports', page: params['page']!, pageSize: params['pageSize']!);
  }

  // Fetch Entertainment news
  Future<List<Article>> fetchEntertainmentNews({int page = 1, int pageSize = 10}) async {
    final params = _validatePaginationParams(page: page, pageSize: pageSize);
    return _fetchNewsByCategory('entertainment', page: params['page']!, pageSize: params['pageSize']!);
  }

  // Fetch Business news
  Future<List<Article>> fetchBusinessNews({int page = 1, int pageSize = 10}) async {
    final params = _validatePaginationParams(page: page, pageSize: pageSize);
    return _fetchNewsByCategory('business', page: params['page']!, pageSize: params['pageSize']!);
  }

  // Fetch Health news
  Future<List<Article>> fetchHealthNews({int page = 1, int pageSize = 10}) async {
    final params = _validatePaginationParams(page: page, pageSize: pageSize);
    return _fetchNewsByCategory('health', page: params['page']!, pageSize: params['pageSize']!);
  }

  // Fetch Random General news
  Future<List<Article>> fetchGeneralNews({int page = 1, int pageSize = 10}) async {
    final cacheKey = 'general_${page}_$pageSize';
    
    // Check cache first
    final cached = _getCachedResponse(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    try {
      final url = '${ApiConfig.newsUrl}/general?page=$page&pageSize=$pageSize';
      final response = await _makeRequest(url);
      final articles = _handleResponse(response);
      
      // Cache the response
      _cacheResponse(cacheKey, articles);
      return articles;
    } catch (e) {
      if (e is NewsServiceException) {
        rethrow;
      }
      throw NewsServiceException('Failed to fetch general news: $e');
    }
  }

  // Fetch Politics news
  Future<List<Article>> fetchPoliticsNews({int page = 1, int pageSize = 10}) async {
    final cacheKey = 'politics_${page}_$pageSize';
    
    // Check cache first
    final cached = _getCachedResponse(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    try {
      final url = '${ApiConfig.newsUrl}/politics?page=$page&pageSize=$pageSize';
      final response = await _makeRequest(url);
      final articles = _handleResponse(response);
      
      // Cache the response
      _cacheResponse(cacheKey, articles);
      return articles;
    } catch (e) {
      if (e is NewsServiceException) {
        rethrow;
      }
      throw NewsServiceException('Failed to fetch politics news: $e');
    }
  }

  // Search news by query
  Future<List<Article>> searchNews(String query, {int page = 1, int pageSize = 10}) async {
    if (query.trim().isEmpty) {
      throw NewsServiceException('Search query cannot be empty');
    }
    
    final cacheKey = 'search_${query}_${page}_$pageSize';
    
    // Check cache first
    final cached = _getCachedResponse(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '${ApiConfig.newsUrl}/search?q=$encodedQuery&page=$page&pageSize=$pageSize';
      final response = await _makeRequest(url);
      final articles = _handleResponse(response);
      
      // Cache the response
      _cacheResponse(cacheKey, articles);
      return articles;
    } catch (e) {
      if (e is NewsServiceException) {
        rethrow;
      }
      throw NewsServiceException('Failed to search news: $e');
    }
  }

  // Fetch news by category with caching and error handling
  Future<List<Article>> _fetchNewsByCategory(String category, {int page = 1, int pageSize = 10}) async {
    if (category.trim().isEmpty) {
      throw NewsServiceException('Category cannot be empty');
    }
    
    final cacheKey = '${category}_${page}_$pageSize';
    
    // Check cache first
    final cached = _getCachedResponse(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    try {
      final url = '${ApiConfig.newsUrl}/category/$category?page=$page&pageSize=$pageSize';
      final response = await _makeRequest(url);
      final articles = _handleResponse(response);
      
      // Cache the response
      _cacheResponse(cacheKey, articles);
      return articles;
    } catch (e) {
      if (e is NewsServiceException) {
        rethrow;
      }
      throw NewsServiceException('Failed to fetch $category news: $e');
    }
  }  // Enhanced response handling with better error messages
  List<Article> _handleResponse(http.Response response) {
    try {
      if (response.statusCode != 200) {
        throw ServerException(
          'HTTP ${response.statusCode}: ${_getErrorMessage(response.statusCode)}',
          response.statusCode
        );
      }
      
      final Map<String, dynamic> data = jsonDecode(response.body);
      
      // Handle both direct NewsAPI format and our backend wrapper format
      final dynamic articlesData = data['data']?['articles'] ?? data['articles'];
      
      if (articlesData == null) {
        throw NewsServiceException('No articles found in response');
      }
      
      if (articlesData is! List) {
        throw NewsServiceException('Invalid articles format in response');
      }
      
      final articles = _parseArticles(articlesData);
      
      if (articles.isEmpty) {
        // Return empty list instead of throwing error for no results
        return [];
      }
      
      return articles;
    } catch (e) {
      if (e is NewsServiceException) {
        rethrow;
      } else if (e is FormatException) {
        throw NewsServiceException('Invalid JSON response format');
      } else {
        throw NewsServiceException('Failed to process response: $e');
      }
    }
  }

  // Enhanced article parsing with validation
  List<Article> _parseArticles(List<dynamic> articlesJson) {
    final List<Article> validArticles = [];
    
    for (final articleData in articlesJson) {
      try {
        if (articleData is Map<String, dynamic> && _isValidArticle(articleData)) {
          final article = Article.fromJson(articleData);
          validArticles.add(article);
        }
      } catch (e) {
        // Log invalid article but continue processing others
        Log.e('Warning: Failed to parse article: $e');
        continue;
      }
    }
    
    return validArticles;
  }
  
  // Validate article data before parsing
  bool _isValidArticle(Map<String, dynamic> articleData) {
    return articleData['title'] != null && 
           articleData['title'].toString().trim().isNotEmpty &&
           articleData['urlToImage'] != null &&
           articleData['urlToImage'].toString().trim().isNotEmpty &&
           articleData['description'] != null &&
           articleData['url'] != null;
  }
  
  // Get user-friendly error messages for HTTP status codes
  String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request - Please check your parameters';
      case 401:
        return 'Unauthorized - API key may be invalid';
      case 403:
        return 'Forbidden - Access denied';
      case 404:
        return 'Not found - The requested resource was not found';
      case 429:
        return 'Rate limit exceeded - Too many requests';
      case 500:
        return 'Internal server error - Please try again later';
      case 502:
        return 'Bad gateway - Server is temporarily unavailable';
      case 503:
        return 'Service unavailable - Server is down for maintenance';
      default:
        return 'Unknown error occurred';
    }
  }
  
  // Utility methods for service management
  
  // Clear all cached data
  void clearCache() {
    _cache.clear();
  }
  
  // Check if service is initialized
  bool get isInitialized => _isInitialized;
  
  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final int totalEntries = _cache.length;
    final int expiredEntries = _cache.values
        .where((cached) => cached.isExpired)
        .length;
    
    return {
      'totalEntries': totalEntries,
      'activeEntries': totalEntries - expiredEntries,
      'expiredEntries': expiredEntries,
    };
  }
  
  // Clean up expired cache entries
  void cleanExpiredCache() {
    _cache.removeWhere((key, cached) => cached.isExpired);
  }
  
  // Get all available categories
  static List<String> getAvailableCategories() {
    return [
      'general',
      'business',
      'entertainment',
      'health',
      'science',
      'sports',
      'technology',
    ];
  }
  
  // Fetch news from multiple categories
  Future<Map<String, List<Article>>> fetchMultipleCategories(
    List<String> categories, {
    int page = 1,
    int pageSize = 5,
  }) async {
    final Map<String, List<Article>> results = {};
    
    // Use Future.wait to fetch all categories concurrently
    final futures = categories.map((category) async {
      try {
        final articles = await _fetchNewsByCategory(
          category,
          page: page,
          pageSize: pageSize,
        );
        return MapEntry(category, articles);
      } catch (e) {
        // Return empty list for failed categories instead of failing entirely
        Log.e('Warning: Failed to fetch $category news: $e');
        return MapEntry(category, <Article>[]);
      }
    });
    
    final entries = await Future.wait(futures);
    for (final entry in entries) {
      results[entry.key] = entry.value;
    }
    
    return results;
  }
  
  // Health check method
  Future<bool> checkServiceHealth() async {
    try {
      await fetchTrendingNews(pageSize: 1);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get trending topics based on search queries
  Future<List<Article>> fetchTrendingTopics({
    int pageSize = 20,
  }) async {
    final trendingQueries = [
      'breaking news',
      'trending',
      'latest news',
    ];
    
    try {
      // Try with the most popular query first
      return await searchNews(trendingQueries.first, pageSize: pageSize);
    } catch (e) {
      // Fallback to general news
      return await fetchTrendingNews(pageSize: pageSize);
    }
  }
}
