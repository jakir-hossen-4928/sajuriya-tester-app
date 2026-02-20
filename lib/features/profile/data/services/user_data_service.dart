import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/models/models.dart';

class ProfileService {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<void> updateProfile({
    required String userId,
    String? fullName,
  }) async {
    final Map<String, dynamic> updates = {
      'full_name': ?fullName,
      'updated_at': DateTime.now().toIso8601String(),
    };
    debugPrint('[ProfileService] Updating profile for $userId: $updates');
    try {
      await _client.from('profiles').update(updates).eq('id', userId);
      debugPrint('[ProfileService] Profile updated successfully');
    } catch (e) {
      debugPrint('[ProfileService] Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> updateAvatar(String userId, String avatarUrl) async {
    await _client.from('profiles').update({
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<Profile> getProfile(String userId) async {
    debugPrint('[ProfileService] Fetching profile for $userId');
    try {
      final profile = await _client.from('profiles').select().eq('id', userId).single();
      debugPrint('[ProfileService] Profile fetched: $profile');
      return Profile.fromMap(profile);
    } catch (e) {
      debugPrint('[ProfileService] Error fetching profile: $e');
      rethrow;
    }
  }

  Stream<Profile?> streamProfile(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => data.isNotEmpty ? Profile.fromMap(data.first) : null);
  }
}

class AppService {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<String> createAppListing({
    required String developerId,
    required String appName,
    required String packageName,
    required String playStoreUrl,
    required String logoUrl,
    String? description,
  }) async {
    debugPrint('[AppService] Creating app listing for user: $developerId');
    try {
      final response = await _client.rpc('create_app_listing', params: {
        'p_developer_id': developerId,
        'p_app_name': appName,
        'p_package_name': packageName,
        'p_playstore_url': playStoreUrl,
        'p_app_icon': logoUrl, 
        'p_description': description,
      });
      
      final appId = response as String;
      debugPrint('[AppService] App created via RPC with ID: $appId');
      return appId;
    } catch (e) {
      debugPrint('[AppService] Error creating app: $e');
      rethrow;
    }
  }

  Future<void> updateApp({
    required String appId,
    String? appName,
    String? packageName,
    String? playStoreUrl,
    String? description,
  }) async {
    final Map<String, dynamic> updates = {
      'app_name': ?appName,
      'package_name': ?packageName,
      'playstore_url': ?playStoreUrl,
      'description': ?description,
    };
    await _client.from('apps').update(updates).eq('id', appId);
  }

  Future<List<AppModel>> getDeveloperApps(String developerId) async {
    final response = await _client
        .from('apps')
        .select()
        .eq('developer_id', developerId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => AppModel.fromMap(e)).toList();
  }

  Future<void> deleteApp(String appId) async {
    await _client.from('apps').delete().eq('id', appId);
  }
}

class KarmaService {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<void> completeTesting(String assignmentId, String screenshotUrl) async {
    await _client.rpc('complete_test_assignment', params: {
      'p_assignment_id': assignmentId,
      'p_screenshot_url': screenshotUrl,
    });
  }

  Future<List<KarmaTransaction>> getTransactionHistory(String userId) async {
    final response = await _client
        .from('karma_transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => KarmaTransaction.fromMap(e)).toList();
  }

  Stream<List<KarmaTransaction>> streamTransactionHistory(String userId) {
    return _client
        .from('karma_transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => KarmaTransaction.fromMap(e)).toList());
  }
}
