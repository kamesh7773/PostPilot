import 'package:flutter/foundation.dart';

/// The brand you post for in Live QR posts (dev only), from `GET /brands`.
@immutable
class Brand {
  final String id;
  final String name;

  /// What the AI must know about the brand; used for every post.
  final String brief;
  final BrandAccount? account;

  const Brand({
    required this.id,
    required this.name,
    required this.brief,
    this.account,
  });

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
    id: json['id'] as String,
    name: json['name'] as String,
    brief: json['brief'] as String,
    account: json['account'] == null
        ? null
        : BrandAccount.fromJson(json['account'] as Map<String, dynamic>),
  );
}

/// The Instagram account a brand posts to, and whether its Facebook Page can get the same posts.
@immutable
class BrandAccount {
  final String id;
  final String username;
  final String? facebookPageName;

  /// False for accounts connected before Live QR posts: reconnect to save the Page's token.
  final bool canPostToFacebook;
  final bool needsReconnect;

  const BrandAccount({
    required this.id,
    required this.username,
    this.facebookPageName,
    required this.canPostToFacebook,
    required this.needsReconnect,
  });

  factory BrandAccount.fromJson(Map<String, dynamic> json) => BrandAccount(
    id: json['id'] as String,
    username: json['username'] as String,
    facebookPageName: json['facebookPageName'] as String?,
    canPostToFacebook: json['canPostToFacebook'] as bool,
    needsReconnect: json['status'] == 'needs_reauth',
  );
}
