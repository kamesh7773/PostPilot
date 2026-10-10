import '../config/env.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => Env.apiBaseUrl;

  // Current user
  static const String me = '/me';

  // Social accounts
  static const String socialAccounts = '/social-accounts';
  static String socialAccount(String id) => '/social-accounts/$id';
  static const String instagramConnectStart = '/auth/instagram/start';

  // Media & posts
  static const String posts = '/posts';
  static String post(String id) => '/posts/$id';
  static String publishPost(String id) => '/posts/$id/publish';

  // Push notifications
  static const String devices = '/devices';

  // Creator profile & AI
  static const String profile = '/profile';
  static const String aiPlan = '/ai/plan';
  static const String plan = '/plan';
  static String planItem(String id) => '/plan/$id';

  // Exemple of api endpoints
  // static const String products = '/products';
  // static String productById(int id) => '/products/$id';
  // static const String categories = '/categories';
}
