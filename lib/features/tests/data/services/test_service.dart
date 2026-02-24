import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/models/app_model.dart';
import '../../../../core/models/test_assignment_model.dart';

class TestService {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<TestAssignment>> getActiveAssignments(String userId) async {
    final response = await _client
        .from('test_assignments')
        .select('*, apps(*)')
        .eq('developer_id', userId)
        .eq('is_completed', false);
    
    return (response as List).map((e) {
      try {
        return TestAssignment.fromMap(e);
      } catch (err) {
        debugPrint('[TestService] Skipping malformed active assignment: $err');
        return null;
      }
    }).whereType<TestAssignment>().toList();
  }

  Future<List<TestAssignment>> getCompletedAssignments(String userId) async {
    final response = await _client
        .from('test_assignments')
        .select('*, apps(*)')
        .eq('developer_id', userId)
        .eq('is_completed', true);

    return (response as List).map((e) {
      try {
        return TestAssignment.fromMap(e);
      } catch (err) {
        debugPrint('[TestService] Skipping malformed completed assignment: $err');
        return null;
      }
    }).whereType<TestAssignment>().toList();
  }

  /// Returns true if the user already has an assignment (active OR completed)
  /// for the given [appId].
  Future<bool> hasAlreadyTested(String userId, String appId) async {
    final existing = await _client
        .from('test_assignments')
        .select('id')
        .eq('developer_id', userId)
        .eq('app_id', appId)
        .maybeSingle();
    return existing != null;
  }

  Future<void> startTesting(String userId, String appId) async {
    // Check if already assigned
    final existing = await _client
        .from('test_assignments')
        .select()
        .eq('developer_id', userId)
        .eq('app_id', appId)
        .maybeSingle();

    if (existing != null) return;

    await _client.from('test_assignments').insert({
      'developer_id': userId,
      'app_id': appId,
      'test_status': 'in_progress',
    });
  }

  Future<void> submitTestProof({
    required String assignmentId,
    required String screenshotUrl,
  }) async {
    await _client.rpc('complete_test_assignment', params: {
      'p_assignment_id': assignmentId,
      'p_screenshot_url': screenshotUrl,
    });
  }
}
