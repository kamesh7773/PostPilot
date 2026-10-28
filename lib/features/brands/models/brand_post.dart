import 'package:flutter/foundation.dart';

/// A Live QR post: made by AI, changed on request, published only once approved.
@immutable
class BrandPost {
  final String id;
  final String format;
  final String idea;

  /// Every change the owner asked for, oldest first.
  final List<String> changeRequests;
  final String caption;

  /// Made from the owner's own files, not by AI.
  final bool own;
  final List<String> mediaUrls;

  /// generating → review → approved; failed when the AI couldn't make it.
  final String status;
  final String? error;
  final PublishState? instagram;
  final PublishState? facebook;
  final DateTime createdAt;

  const BrandPost({
    required this.id,
    required this.format,
    required this.idea,
    required this.changeRequests,
    required this.caption,
    this.own = false,
    required this.mediaUrls,
    required this.status,
    this.error,
    this.instagram,
    this.facebook,
    required this.createdAt,
  });

  factory BrandPost.fromJson(Map<String, dynamic> json) => BrandPost(
    id: json['id'] as String,
    format: json['format'] as String,
    idea: json['idea'] as String,
    changeRequests: (json['changeRequests'] as List).cast<String>(),
    caption: json['caption'] as String,
    own: json['own'] as bool? ?? false,
    mediaUrls: (json['mediaUrls'] as List).cast<String>(),
    status: json['status'] as String,
    error: json['error'] as String?,
    instagram: PublishState.fromJson(json['instagram']),
    facebook: PublishState.fromJson(json['facebook']),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  bool get isGenerating => status == 'generating';
  bool get inReview => status == 'review';
  bool get isApproved => status == 'approved';
  bool get isFailed => status == 'failed';

  /// Approved and still going out to Instagram or Facebook.
  bool get isPublishing =>
      isApproved && ((instagram?.isBusy ?? true) || (facebook?.isBusy ?? true));

  /// Approved, but Instagram or Facebook gave up: approving again retries it.
  bool get publishFailed =>
      isApproved &&
      !isPublishing &&
      ((instagram?.isFailed ?? false) || (facebook?.isFailed ?? false));

  static const labels = {
    'image': 'Post',
    'carousel': 'Carousel',
    'story': 'Story',
    'reel': 'Reel',
  };

  String get label => labels[format] ?? 'Post';
}

/// Where a post stands on Instagram or the Facebook Page.
@immutable
class PublishState {
  final String status;
  final String? permalink;
  final String? error;

  const PublishState({required this.status, this.permalink, this.error});

  static PublishState? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return PublishState(
      status: json['status'] as String,
      permalink: json['permalink'] as String?,
      error: json['error'] as String?,
    );
  }

  bool get isDone => status == 'published';
  bool get isFailed => status == 'failed';
  bool get isBusy => !isDone && !isFailed;
}
