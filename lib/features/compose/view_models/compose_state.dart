import 'package:flutter/foundation.dart';

import '../services/reel_video.dart';

enum MediaKind { photo, reel, story, carousel }

/// Instagram allows 2–10 items per carousel.
const maxCarouselItems = 10;

/// One prepared carousel item: a photo or a video.
@immutable
class CarouselItem {
  final String? imagePath;
  final PreparedVideo? video;

  const CarouselItem.photo(String this.imagePath) : video = null;
  const CarouselItem.video(PreparedVideo this.video) : imagePath = null;
}

enum ComposeStep {
  idle,

  /// Converting/cropping the photo or encoding the video on the device.
  preparing,
  uploading,

  /// Waiting for Instagram to process and publish.
  publishing,
}

@immutable
class ComposeState {
  final String? accountId;
  final MediaKind kind;

  /// Photo: prepared JPEG path.
  final String? imagePath;

  /// The photo was center-cropped to fit Instagram's aspect-ratio range.
  final bool wasCropped;

  /// Reel: encoded video.
  final PreparedVideo? video;

  /// Carousel: items in posting order.
  final List<CarouselItem> items;
  final bool shareToFeed;

  /// Local time to publish at; null means publish now.
  final DateTime? scheduledAt;

  /// The AI plan slot this post fills, if opened from the plan.
  final String? planItemId;

  final ComposeStep step;

  /// 0.0–1.0 for the current step when known (encoding, uploading).
  final double? progress;

  const ComposeState({
    this.accountId,
    this.kind = MediaKind.photo,
    this.imagePath,
    this.wasCropped = false,
    this.video,
    this.items = const [],
    this.shareToFeed = true,
    this.scheduledAt,
    this.planItemId,
    this.step = ComposeStep.idle,
    this.progress,
  });

  bool get isBusy => step != ComposeStep.idle;

  bool get hasMedia => switch (kind) {
    MediaKind.photo => imagePath != null,
    MediaKind.reel => video != null,
    // A Story is either a photo or a video.
    MediaKind.story => imagePath != null || video != null,
    MediaKind.carousel => items.length >= 2,
  };

  bool get canPublish => accountId != null && hasMedia && !isBusy;

  /// Leaving is fine once Instagram is processing (it continues server-side),
  /// but not while the device is still preparing or uploading.
  bool get canLeave =>
      step == ComposeStep.idle || step == ComposeStep.publishing;

  static const _sentinel = Object();

  ComposeState copyWith({
    Object? accountId = _sentinel,
    MediaKind? kind,
    Object? imagePath = _sentinel,
    bool? wasCropped,
    Object? video = _sentinel,
    List<CarouselItem>? items,
    bool? shareToFeed,
    Object? scheduledAt = _sentinel,
    String? planItemId,
    ComposeStep? step,
    Object? progress = _sentinel,
  }) => ComposeState(
    accountId: accountId == _sentinel ? this.accountId : accountId as String?,
    kind: kind ?? this.kind,
    imagePath: imagePath == _sentinel ? this.imagePath : imagePath as String?,
    wasCropped: wasCropped ?? this.wasCropped,
    video: video == _sentinel ? this.video : video as PreparedVideo?,
    items: items ?? this.items,
    shareToFeed: shareToFeed ?? this.shareToFeed,
    scheduledAt: scheduledAt == _sentinel
        ? this.scheduledAt
        : scheduledAt as DateTime?,
    planItemId: planItemId ?? this.planItemId,
    step: step ?? this.step,
    progress: progress == _sentinel
        ? this.progress
        : (progress as num?)?.toDouble(),
  );
}
