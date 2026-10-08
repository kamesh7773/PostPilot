class AppConstants {
  AppConstants._();

  static const String appName = 'PostPilot';

  // Custom URL scheme the backend redirects to at the end of OAuth flows.
  // Must match the backend's APP_OAUTH_RETURN_URL and the Android manifest.
  static const String oauthCallbackScheme = 'postpilot';

  // Design reference size for ScreenUtil
  static const double designWidth = 375;
  static const double designHeight = 812;

  // Network
  static const Duration connectionTimeout = Duration(seconds: 300);
  static const Duration receiveTimeout = Duration(seconds: 300);
  static const Duration sendTimeout = Duration(seconds: 300);
}
