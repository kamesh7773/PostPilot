import 'package:flutter/foundation.dart';

@immutable
class GeneratedCaption {
  final String caption;
  final List<String> hashtags;

  const GeneratedCaption({required this.caption, required this.hashtags});

  factory GeneratedCaption.fromJson(Map<String, dynamic> json) =>
      GeneratedCaption(
        caption: json['caption'] as String,
        hashtags: List<String>.from(json['hashtags'] as List),
      );

  /// Caption with hashtags appended, ready for the caption field.
  String get full =>
      '$caption\n\n${hashtags.map((h) => h.startsWith('#') ? h : '#$h').join(' ')}';
}
