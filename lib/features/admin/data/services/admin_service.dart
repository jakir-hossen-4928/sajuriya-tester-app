import '../../../../core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/models.dart';

class AdminService {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<Map<String, dynamic>> getStats() async {
    final usersRes = await _client.from('profiles').select('id');
    final appsRes = await _client.from('apps').select('id').eq('status', 'active');
    final testsRes = await _client.from('test_assignments').select('id').eq('is_completed', true);
    
    // Summing karma
    final karmaRes = await _client.from('profiles').select('credits');
    int totalKarma = 0;
    for (var row in karmaRes) {
      totalKarma += (row['credits'] as int? ?? 0);
    }

    return {
      'totalUsers': usersRes.length,
      'activeApps': appsRes.length,
      'completedTests': testsRes.length,
      'totalKarma': totalKarma,
    };
  }

  Future<List<Profile>> getAllUsers({String? query}) async {
    var request = _client.from('profiles').select('*, apps(count)');
    
    if (query != null && query.isNotEmpty) {
      request = request.or('full_name.ilike.%$query%,email.ilike.%$query%');
    }
    
    final response = await request.order('created_at', ascending: false);
    return (response as List).map((e) => Profile.fromMap(e)).toList();
  }

  Future<List<AppModel>> getAllApps({String? query}) async {
var request = _client.from('apps').select('*, profiles(full_name, email, avatar_url, credits, role, created_at, updated_at)');    
    if (query != null && query.isNotEmpty) {
      request = request.or('app_name.ilike.%$query%,package_name.ilike.%$query%');
    }
    
    final response = await request.order('created_at', ascending: false);
    return (response as List).map((e) => AppModel.fromMap(e)).toList();
  }


  Future<void> removeApp(String appId) async {
    await _client.from('apps').delete().eq('id', appId);
  }

  Future<void> updateAppStatus(String appId, String status) async {
    await _client.from('apps').update({'status': status}).eq('id', appId);
  }

  Future<void> updateAppDetails(String appId, Map<String, dynamic> updates) async {
    await _client.from('apps').update(updates).eq('id', appId);
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _client.from('profiles').update({'role': role}).eq('id', userId);
  }

  Future<void> adjustUserCredits(String userId, int credits) async {
    await _client.from('profiles').update({'credits': credits}).eq('id', userId);
  }

  Future<void> deleteUser(String userId) async {
    // Note: This might need careful handling with foreign keys
    await _client.from('profiles').delete().eq('id', userId);
  }

  Future<Map<String, int>> getPendingCounts() async {
    final completedTests = await _client
        .from('test_assignments')
        .select('id')
        .eq('test_status', 'completed')
        .eq('is_completed', true);
    
    return {
      'completedTests': completedTests.length,
    };
  }
}
