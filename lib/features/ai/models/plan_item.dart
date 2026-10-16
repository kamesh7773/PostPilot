import 'package:flutter/foundation.dart';

/// One slot of the AI weekly plan. Filled once the user adds media and the
/// post is created ([postId] set).
@immutable
class PlanItem {
  final String id;

  /// image | reel | story | carousel
  final String format;

  /// Local date (YYYY-MM-DD) and time (HH:MM) on this device.
  final String date;
  final String time;
  final String title;
  final String hook;
  final String caption;
  final String why;
  final String? postId;

  /// Status of the post made from this slot (scheduled, published, ...).
  final String? postStatus;

  /// Autopilot: off (user adds media), pending, generating, ready, failed.
  final String autoStatus;
  final String? autoError;

  /// Preview of the generated photo (null for Reels and unfilled slots).
  final String? mediaUrl;

  /// All generated media: carousel slides, or the Reel's video.
  final List<String> mediaUrls;

  const PlanItem({
    required this.id,
    required this.format,
    required this.date,
    required this.time,
    required this.title,
    required this.hook,
    required this.caption,
    required this.why,
    this.postId,
    this.postStatus,
    this.autoStatus = 'off',
    this.autoError,
    this.mediaUrl,
    this.mediaUrls = const [],
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
    id: json['id'] as String,
    format: json['format'] as String,
    date: json['date'] as String,
    time: json['time'] as String,
    title: json['title'] as String,
    hook: json['hook'] as String? ?? '',
    caption: json['caption'] as String? ?? '',
    why: json['why'] as String? ?? '',
    postId: json['postId'] as String?,
    postStatus: json['postStatus'] as String?,
    autoStatus: json['autoStatus'] as String? ?? 'off',
    autoError: json['autoError'] as String?,
    mediaUrl: json['mediaUrl'] as String?,
    mediaUrls: (json['mediaUrls'] as List? ?? const []).cast<String>(),
  );

  bool get isFilled => postId != null;

  // Backend reasons that are already written for users; anything else is a
  // raw provider error (quota, model, network) and is kept out of the UI.
  static const _userMessages = {
    'This time has passed. Pick a later time to try again.',
    'Connect Instagram, then try again.',
    'Weekly autopilot limit reached. Try again later this week.',
  };

  /// What to show for a failed slot (null when there is no error).
  String? get friendlyError => autoError == null
      ? null
      : _userMessages.contains(autoError)
      ? autoError
      : "We couldn't create this one. Please try again in a few minutes.";

  /// Time and caption can change until the post starts publishing.
  bool get isEditable => postStatus == null || postStatus == 'scheduled';

  /// The AI is still making this slot's photo or video.
  bool get isGenerating =>
      autoStatus == 'pending' || autoStatus == 'generating';

  /// Local DateTime of the slot.
  DateTime get when => DateTime.parse('${date}T$time:00');
}
