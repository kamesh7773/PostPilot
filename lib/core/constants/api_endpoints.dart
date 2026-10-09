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
  static const String media = '/media';
  static const String videoUploadUrl = '/media/video-upload-url';
  static const String posts = '/posts';
  static String post(String id) => '/posts/$id';
  static String publishPost(String id) => '/posts/$id/publish';

  // Exemple of api endpoints
  // static const String products = '/products';
  // static String productById(int id) => '/products/$id';
  // static const String categories = '/categories';
}
