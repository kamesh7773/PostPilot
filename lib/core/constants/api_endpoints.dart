import '../config/env.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => Env.apiBaseUrl;

  // Exemple of api endpoints
  // static const String products = '/products';
  // static String productById(int id) => '/products/$id';
  // static const String categories = '/categories';
}
