import 'app_model.dart';

class TestAssignment {
  final String id;
  final String developerId;
  final String appId;
  final bool isCompleted;
  final String testStatus;
  final String? screenshotUrl;
  final DateTime startDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final AppModel? app; // Join with apps

  TestAssignment({
    required this.id,
    required this.developerId,
    required this.appId,
    required this.isCompleted,
    required this.testStatus,
    this.screenshotUrl,
    required this.startDate,
    this.completedAt,
    required this.createdAt,
    this.app,
  });

  factory TestAssignment.fromMap(Map<String, dynamic> map) {
    return TestAssignment(
      id: map['id'],
      developerId: map['developer_id'],
      appId: map['app_id'],
      isCompleted: map['is_completed'] ?? false,
      testStatus: map['test_status'] ?? 'in_progress',
      screenshotUrl: map['screenshot_url'],
      startDate: DateTime.parse(map['start_date']),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null,
      createdAt: DateTime.parse(map['created_at']),
      app: map['apps'] != null ? AppModel.fromMap(map['apps']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'developer_id': developerId,
      'app_id': appId,
      'is_completed': isCompleted,
      'test_status': testStatus,
      'screenshot_url': screenshotUrl,
      'start_date': startDate.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'apps': app?.toMap(),
    };
  }
}
