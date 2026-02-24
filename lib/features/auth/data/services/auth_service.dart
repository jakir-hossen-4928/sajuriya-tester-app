import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/models/models.dart';
import '../../../../core/config/supabase_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  SupabaseClient get _client => SupabaseConfig.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signInWithGoogle() async {
    final webClientId = dotenv.get('WEB_CLIENT');
    final iosClientId = dotenv.get('IOS_CLEINT');

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw 'Google sign-in was cancelled.';
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw 'Authentication failed: No ID Token returned from Google.';
    }

    // Supabase will create the user if they don't exist.
    // The database trigger will handle profile creation + 50 karma credits.
    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    // Sync Google avatar, display name & email into profiles for every sign-in.
    // This keeps returning users' avatars up to date even after a profile picture change.
    await _syncGoogleProfile(response.user);

    return response;
  }

  /// Upserts the Google avatar URL, full name, and email into the profiles table.
  /// Called after every successful Google sign-in (new or returning user).
  Future<void> _syncGoogleProfile(User? user) async {
    if (user == null) return;
    try {
      final meta = user.userMetadata ?? {};
      // Google stores the picture in 'avatar_url' or 'picture'
      final avatarUrl = (meta['avatar_url'] as String?)?.isNotEmpty == true
          ? meta['avatar_url'] as String
          : meta['picture'] as String?;
      final fullName = meta['full_name'] as String? ?? meta['name'] as String?;
      final email = user.email ?? meta['email'] as String?;

      final payload = <String, dynamic>{
        'id': user.id,
        'updated_at': DateTime.now().toIso8601String(),
        'avatar_url': avatarUrl,
        'full_name': fullName,
        'email': email,
      };

      await _client.from('profiles').upsert(
        payload,
        onConflict: 'id',
        ignoreDuplicates: false,
      );
      debugPrint('[AuthService] Profile synced: avatar_url=$avatarUrl');
    } catch (e) {
      // Non-fatal — profile will still exist from the DB trigger
      debugPrint('[AuthService] Profile sync warning: $e');
    }
  }

  Future<void> signOut() async {
    try {
      if (Hive.isBoxOpen('active_tests')) await Hive.box('active_tests').clear();
      if (Hive.isBoxOpen('completed_tests')) await Hive.box('completed_tests').clear();

      await _client.auth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('[AuthService] Sign out error: $e');
    }
  }

  Future<Profile?> getProfile(String userId) async {
    debugPrint('[AuthService] Getting profile for $userId');
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return Profile.fromMap(response);
    } catch (e) {
      debugPrint('[AuthService] Error fetching profile: $e');
      return null;
    }
  }

  Stream<Profile?> streamProfile(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => data.isNotEmpty ? Profile.fromMap(data.first) : null)
        .handleError((error) {
          debugPrint('[AuthService] Profile stream error: $error');
          return null;
        });
  }

  Future<String?> getUserRole(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      return response['role'] as String?;
    } catch (e) {
      debugPrint('[AuthService] Error getting user role: $e');
      return 'developer';
    }
  }

  Future<bool> isAdmin(String userId) async {
    if (userId.isEmpty) return false;
    final role = await getUserRole(userId);
    return role == 'admin';
  }
}
