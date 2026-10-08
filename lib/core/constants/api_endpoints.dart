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

  // Exemple of api endpoints
  // static const String products = '/products';
  // static String productById(int id) => '/products/$id';
  // static const String categories = '/categories';
}
