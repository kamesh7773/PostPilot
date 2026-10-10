import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/api_endpoints.dart';
import 'api_client.dart';
import 'notification_service.dart';
import 'storage_service.dart';

part 'push_service.g.dart';

/// Registers this device for publish notifications (FCM) with the backend.
@Riverpod(keepAlive: true)
class PushService extends _$PushService {
  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<RemoteMessage>? _foreground;

  @override
  void build() {
    ref.onDispose(() {
      _tokenRefresh?.cancel();
      _foreground?.cancel();
    });
  }

  Dio get _api => ref.read(apiClientProvider);

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  static const _askedKey = 'push_permission_asked';

  /// Call when Home opens. Registers silently if notifications are already
  /// allowed. Returns true when the app should show its explainer screen
  /// first (never asked before); after that the user decides in Settings.
  Future<bool> registerIfAllowed() async {
    if (kIsWeb) return false;
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await register();
        return false;
      }
      final storage = ref.read(storageServiceProvider.notifier);
      return await storage.getBool(_askedKey) != true;
    } catch (e) {
      debugPrint('PushService.registerIfAllowed failed: $e');
      return false;
    }
  }

  /// Shows the system dialog (once allowed it returns at once), then sends
  /// the token. Called from the explainer screen or [registerIfAllowed].
  Future<void> register() async {
    if (kIsWeb) return;
    try {
      await ref.read(storageServiceProvider.notifier).setBool(_askedKey, true);
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      if (_isIos) {
        // iOS shows foreground pushes itself; Android needs a local notification.
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        // The FCM token needs Apple's APNs token, which arrives shortly after launch.
        for (var i = 0; i < 10 && await messaging.getAPNSToken() == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }

      final token = await messaging.getToken();
      if (token != null) await _send(token);

      _tokenRefresh ??= messaging.onTokenRefresh.listen(_send);
      // In the foreground Android doesn't show FCM notifications itself.
      if (!_isIos) {
        _foreground ??= FirebaseMessaging.onMessage.listen(_showForeground);
      }
    } catch (e) {
      debugPrint('PushService.register failed: $e');
    }
  }

  /// Call before sign-out, while the session is still valid.
  Future<void> unregister() async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _api.delete(ApiEndpoints.devices, data: {'token': token});
      }
    } catch (e) {
      debugPrint('PushService.unregister failed: $e');
    }
  }

  Future<void> _send(String token) {
    // Debug builds only: with this token anyone holding our server key can push to the device.
    if (kDebugMode) debugPrint('📲 FCM token posted to /devices: $token');
    return _api.post(
      ApiEndpoints.devices,
      data: {'token': token, 'platform': _isIos ? 'ios' : 'android'},
    );
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await ref
        .read(notificationServiceProvider.notifier)
        .show(
          AppNotification(
            id: message.hashCode & 0x7fffffff,
            title: n.title ?? 'Autocreator',
            body: n.body ?? '',
            channelKey: NotificationChannels.postUpdates,
          ),
        );
  }
}
