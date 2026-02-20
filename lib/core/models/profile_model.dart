import 'package:flutter/foundation.dart';

class Profile {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final int credits;
  final int reputationScore;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? appCount; // Optional for admin views

  Profile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.credits = 0,
    this.reputationScore = 0,
    this.role = 'developer',
    required this.createdAt,
    required this.updatedAt,
    this.appCount,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    try {
      int appCount = 0;
      if (map['apps'] != null) {
        if (map['apps'] is List && (map['apps'] as List).isNotEmpty) {
          appCount = (map['apps'] as List).first['count'] ?? 0;
        } else if (map['apps'] is Map) {
          appCount = map['apps']['count'] ?? 0;
        }
      }

      return Profile(
        id: map['id'] ?? '',
        email: map['email'] ?? '',
        fullName: map['full_name'],
        avatarUrl: map['avatar_url'],
        credits: map['credits'] ?? 0,
        reputationScore: map['reputation_score'] ?? 0,
        role: map['role'] ?? 'developer',
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
        appCount: appCount > 0 ? appCount : map['app_count'],
      );
    } catch (e) {
      debugPrint('[ProfileModel] Error parsing profile: $e. Map: $map');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'credits': credits,
      'reputation_score': reputationScore,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? fullName,
    String? avatarUrl,
    int? credits,
    int? reputationScore,
    String? role,
  }) {
    return Profile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      credits: credits ?? this.credits,
      reputationScore: reputationScore ?? this.reputationScore,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
