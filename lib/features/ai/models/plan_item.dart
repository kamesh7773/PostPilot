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
  );

  bool get isFilled => postId != null;

  /// Local DateTime of the slot.
  DateTime get when => DateTime.parse('${date}T$time:00');
}
