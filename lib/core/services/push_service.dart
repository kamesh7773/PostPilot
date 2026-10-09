import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/api_endpoints.dart';
import 'api_client.dart';
import 'notification_service.dart';

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

  // ponytail: Android only until the iOS APNs key is uploaded to Firebase;
  // then drop this check (the backend already accepts platform: ios).
  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Call after sign-in. Safe to call repeatedly.
  Future<void> register() async {
    if (!_supported) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token != null) await _send(token);

      _tokenRefresh ??= messaging.onTokenRefresh.listen(_send);
      // In the foreground Android doesn't show FCM notifications itself.
      _foreground ??= FirebaseMessaging.onMessage.listen(_showForeground);
    } catch (e) {
      debugPrint('PushService.register failed: $e');
    }
  }

  /// Call before sign-out, while the session is still valid.
  Future<void> unregister() async {
    if (!_supported) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _api.delete(ApiEndpoints.devices, data: {'token': token});
      }
    } catch (e) {
      debugPrint('PushService.unregister failed: $e');
    }
  }

  Future<void> _send(String token) => _api.post(
    ApiEndpoints.devices,
    data: {'token': token, 'platform': 'android'},
  );

  Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await ref
        .read(notificationServiceProvider.notifier)
        .show(
          AppNotification(
            id: message.hashCode & 0x7fffffff,
            title: n.title ?? 'PostPilot',
            body: n.body ?? '',
            channelKey: NotificationChannels.postUpdates,
          ),
        );
  }
}
