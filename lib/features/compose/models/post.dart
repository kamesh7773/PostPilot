import 'package:flutter/foundation.dart';

enum PostType {
  image,
  reel,
  story,
  carousel,
  unknown;

  static PostType fromString(String value) => PostType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => PostType.unknown,
  );
}

enum PostStatus {
  draft,
  scheduled,
  publishing,
  published,
  failed,
  unknown;

  static PostStatus fromString(String value) => PostStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => PostStatus.unknown,
  );
}

/// A post as returned by the backend (`/posts`).
@immutable
class Post {
  final String id;
  final String socialAccountId;
  final PostType type;
  final String caption;
  final String mediaUrl;
  final PostStatus status;
  final String? lastError;
  final String? permalink;
  final DateTime? publishedAt;

  /// When it will publish (local time); also set while waiting to retry.
  final DateTime? scheduledAt;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.socialAccountId,
    required this.type,
    required this.caption,
    required this.mediaUrl,
    required this.status,
    this.lastError,
    this.permalink,
    this.publishedAt,
    this.scheduledAt,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as String,
    socialAccountId: json['socialAccountId'] as String,
    type: PostType.fromString(json['type'] as String? ?? 'image'),
    caption: json['caption'] as String? ?? '',
    mediaUrl: json['mediaUrl'] as String,
    status: PostStatus.fromString(json['status'] as String),
    lastError: json['lastError'] as String?,
    permalink: json['permalink'] as String?,
    publishedAt: json['publishedAt'] == null
        ? null
        : DateTime.parse(json['publishedAt'] as String),
    scheduledAt: json['scheduledAt'] == null
        ? null
        : DateTime.parse(json['scheduledAt'] as String).toLocal(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  bool get isFinished =>
      status == PostStatus.published || status == PostStatus.failed;
}
