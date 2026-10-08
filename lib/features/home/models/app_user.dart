import 'package:flutter/foundation.dart';

/// The signed-in user's profile as stored by the PostPilot backend.
@immutable
class AppUser {
  final String id;
  final String email;
  final String? name;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    this.name,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    email: json['email'] as String,
    name: json['name'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };
}
