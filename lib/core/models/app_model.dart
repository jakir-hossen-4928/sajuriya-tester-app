import 'profile_model.dart';

class AppModel {
  final String id;
  final String developerId;
  final String appName;
  final String packageName;
  final String playStoreUrl;
  final String? appIcon;
  final String? description;
  final int rewardCredits;
  final int requiredTestDays;
  final String status;
  final DateTime createdAt;
  final Profile? developer; // Join with profiles

  AppModel({
    required this.id,
    required this.developerId,
    required this.appName,
    required this.packageName,
    required this.playStoreUrl,
    this.appIcon,
    this.description,
    this.rewardCredits = 10,
    this.requiredTestDays = 14,
    this.status = 'active',
    required this.createdAt,
    this.developer,
  });

  factory AppModel.fromMap(Map<String, dynamic> map) {
    return AppModel(
      id: map['id'],
      developerId: map['developer_id'],
      appName: map['app_name'],
      packageName: map['package_name'],
      playStoreUrl: map['playstore_url'],
      appIcon: map['app_icon'],
      description: map['description'],
      rewardCredits: map['reward_credits'] ?? 10,
      requiredTestDays: map['required_test_days'] ?? 14,
      status: map['status'] ?? 'active',
      createdAt: DateTime.parse(map['created_at']),
      developer: map['profiles'] != null ? Profile.fromMap(map['profiles']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'developer_id': developerId,
      'app_name': appName,
      'package_name': packageName,
      'playstore_url': playStoreUrl,
      'app_icon': appIcon,
      'description': description,
      'reward_credits': rewardCredits,
      'required_test_days': requiredTestDays,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'profiles': developer?.toMap(),
    };
  }
}
