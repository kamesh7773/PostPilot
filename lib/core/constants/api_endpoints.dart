import '../config/env.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => Env.apiBaseUrl;

  // Current user
  static const String me = '/me';
  static const String resetAccount = '/me/reset';

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

  // Live QR posts (dev only)
  static const String brands = '/brands';
  static String brand(String id) => '/brands/$id';
  static String brandPosts(String brandId) => '/brands/$brandId/posts';
  static String brandOwnPosts(String brandId) => '/brands/$brandId/own-posts';
  static String brandPost(String id) => '/brand-posts/$id';
  static String brandPostChanges(String id) => '/brand-posts/$id/changes';
  static String brandPostApprove(String id) => '/brand-posts/$id/approve';

  // Exemple of api endpoints
  // static const String products = '/products';
  // static String productById(int id) => '/products/$id';
  // static const String categories = '/categories';
}
