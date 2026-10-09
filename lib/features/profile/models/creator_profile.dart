import 'package:flutter/foundation.dart';

/// Who the creator is and who they post for; drives every AI suggestion.
@immutable
class CreatorProfile {
  final String niche;
  final String audienceAgeGroup;
  final List<String> targetCountries;
  final List<String> preferredFormats;
  final String language;
  final String tone;

  const CreatorProfile({
    required this.niche,
    required this.audienceAgeGroup,
    required this.targetCountries,
    required this.preferredFormats,
    required this.language,
    required this.tone,
  });

  factory CreatorProfile.fromJson(Map<String, dynamic> json) => CreatorProfile(
    niche: json['niche'] as String,
    audienceAgeGroup: json['audienceAgeGroup'] as String,
    targetCountries: List<String>.from(json['targetCountries'] as List),
    preferredFormats: List<String>.from(json['preferredFormats'] as List),
    language: json['language'] as String,
    tone: json['tone'] as String,
  );

  Map<String, dynamic> toJson() => {
    'niche': niche,
    'audienceAgeGroup': audienceAgeGroup,
    'targetCountries': targetCountries,
    'preferredFormats': preferredFormats,
    'language': language,
    'tone': tone,
  };
}
