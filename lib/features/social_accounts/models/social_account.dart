import 'package:flutter/foundation.dart';

enum SocialPlatform {
  instagram,
  unknown;

  static SocialPlatform fromString(String value) => SocialPlatform.values
      .firstWhere((e) => e.name == value, orElse: () => SocialPlatform.unknown);
}

enum SocialAccountStatus {
  active,
  needsReauth,
  unknown;

  static SocialAccountStatus fromString(String value) {
    switch (value) {
      case 'active':
        return SocialAccountStatus.active;
      case 'needs_reauth':
        return SocialAccountStatus.needsReauth;
      default:
        return SocialAccountStatus.unknown;
    }
  }
}

/// A connected social account as returned by `GET /social-accounts`.
/// Access tokens never leave the backend.
@immutable
class SocialAccount {
  final String id;
  final SocialPlatform platform;
  final String username;
  final String? displayName;
  final String? profilePictureUrl;
  final SocialAccountStatus status;
  final DateTime? tokenExpiresAt;
  final DateTime connectedAt;

  const SocialAccount({
    required this.id,
    required this.platform,
    required this.username,
    this.displayName,
    this.profilePictureUrl,
    required this.status,
    this.tokenExpiresAt,
    required this.connectedAt,
  });

  factory SocialAccount.fromJson(Map<String, dynamic> json) => SocialAccount(
    id: json['id'] as String,
    platform: SocialPlatform.fromString(json['platform'] as String),
    username: json['username'] as String,
    displayName: json['displayName'] as String?,
    profilePictureUrl: json['profilePictureUrl'] as String?,
    status: SocialAccountStatus.fromString(json['status'] as String),
    tokenExpiresAt: json['tokenExpiresAt'] == null
        ? null
        : DateTime.parse(json['tokenExpiresAt'] as String),
    connectedAt: DateTime.parse(json['connectedAt'] as String),
  );
}
