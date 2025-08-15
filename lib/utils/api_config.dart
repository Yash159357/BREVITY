class ApiConfig {
  // Update this URL to match your backend deployment
  static const String baseUrl = 'https://brevitybackend.onrender.com/api';
  
  // For development, use:
  // static const String baseUrl = 'http://localhost:5001/api';
  
  // For Android emulator:
  // static const String baseUrl = 'http://10.0.2.2:5001/api';
  
  // For iOS simulator:
  // static const String baseUrl = 'http://localhost:5001/api';
  
  // API endpoints
  static const String newsEndpoint = '/news';
  static const String geminiEndpoint = '/gemini';
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String bookmarksEndpoint = '/bookmarks';
  
  // Full URLs
  static String get newsUrl => '$baseUrl$newsEndpoint';
  static String get geminiUrl => '$baseUrl$geminiEndpoint';
  static String get authUrl => '$baseUrl$authEndpoint';
  static String get usersUrl => '$baseUrl$usersEndpoint';
  static String get bookmarksUrl => '$baseUrl$bookmarksEndpoint';
}
