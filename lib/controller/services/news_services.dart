import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:brevity/models/article_model.dart';

class NewsService {

  static final String _apiKey = dotenv.env['NEWS_API_KEY']!;
  static const String _topHeadlinesUrl = 'https://newsapi.org/v2/top-headlines';
  static const String _everythingUrl = 'https://newsapi.org/v2/everything';

  // Fetch trending news
  Future<List<Article>> fetchTrendingNews({int page = 1, int pageSize = 10}) async {
    return _fetchNewsByCategory('general', page: page, pageSize: pageSize);
  }

  // Fetch Technology news
  Future<List<Article>> fetchTechnologyNews({int page = 1, int pageSize = 10}) async {
    return _fetchNewsByCategory('technology', page: page, pageSize: pageSize); 
  }

  // Fetch Sports news
  Future<List<Article>> fetchSportsNews({int page = 1, int pageSize = 10}) async {
    return _fetchNewsByCategory('sports', page: page, pageSize: pageSize);
  }

  // Fetch Entertainment news
  Future<List<Article>> fetchEntertainmentNews({int page = 1, int pageSize = 10}) async {
    return _fetchNewsByCategory('entertainment', page: page, pageSize: pageSize);
  }

  // Fetch Business news
  Future<List<Article>> fetchBusinessNews({int page = 1, int pageSize = 10}) async {
    return _fetchNewsByCategory('business', page: page, pageSize: pageSize);
  }

  // Fetch Health news
  Future<List<Article>> fetchHealthNews({int page = 1, int pageSize = 10}) async {
    return _fetchNewsByCategory('health', page: page, pageSize: pageSize);
  }

  // Fetch Random General news
  Future<List<Article>> fetchGeneralNews({int page = 1, int pageSize = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_topHeadlinesUrl?country=us&page=$page&pageSize=$pageSize&apiKey=$_apiKey')
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch articles: $e');
    }
  }

  // Fetch Politics news with everything endpoint
  Future<List<Article>> fetchPoliticsNews({int page = 1, int pageSize = 10}) async {
    final response = await http.get(
      Uri.parse('$_everythingUrl?q=politics&language=en&sortBy=publishedAt&page=$page&pageSize=$pageSize&apiKey=$_apiKey')
    );
    return _handleResponse(response);
  }

  // Fetch news by search query
  Future<List<Article>> searchNews(String query, {int page = 1, int pageSize = 10}) async {
  final response = await http.get(
    Uri.parse('$_everythingUrl?q=$query&language=en&sortBy=relevancy&page=$page&pageSize=$pageSize&apiKey=$_apiKey')
  );
  return _handleResponse(response);
  }

  Future<List<Article>> _fetchNewsByCategory(String category, {int page = 1, int pageSize = 10}) async {
    final response = await http.get(
      Uri.parse('$_topHeadlinesUrl?country=us&category=$category&page=$page&pageSize=$pageSize&apiKey=$_apiKey')
    );
    return _handleResponse(response);
  }


  List<Article> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return _parseArticles(data['articles']);
    } else {
      throw Exception('Failed to load articles: ${response.statusCode}');
    }
  }

  List<Article> _parseArticles(List<dynamic> articlesJson) {
    return articlesJson
        .where((article) => article['title'] != null && article['urlToImage'] != null)
        .map((articleJson) => Article.fromJson(articleJson))
        .toList();
  }
}
