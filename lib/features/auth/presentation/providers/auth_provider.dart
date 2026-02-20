import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/models.dart';
import '../../data/services/auth_service.dart';
import '../../../../core/providers/common_providers.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user ?? ref.read(authServiceProvider).currentUser;
});

final userRoleProvider = FutureProvider.family<String?, String>((ref, userId) {
  return ref.watch(authServiceProvider).getUserRole(userId);
});

/// Real-time User Profile Provider
/// Uses a [StreamProvider.family] to handle real-time updates from Supabase.
/// It also handles local caching for optimistic UI.
final userProfileProvider = StreamProvider.family<Profile?, String>((ref, userId) async* {
  // 0. Watch auth state to terminate stream on sign-out
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield null;
    return;
  }

  final cache = ref.read(localCacheServiceProvider);
  final auth = ref.read(authServiceProvider);

  // 1. Yield cached data immediately for optimistic UI
  final cached = cache.getProfileSync(userId);
  if (cached != null) {
    yield cached;
  }

  // 2. Stream real-time updates and update cache as we go
  yield* auth.streamProfile(userId).map((profile) {
    if (profile != null) {
      cache.saveProfile(profile);
    }
    return profile;
  });
});

final isAdminProvider = FutureProvider.family<bool, String>((ref, userId) {
  return ref.watch(authServiceProvider).isAdmin(userId);
});

/// Real-time admin status derived from the live profile stream.
/// Used by GoRouter redirect to guard /admin routes without a separate DB call.
final currentUserIsAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final profileAsync = ref.watch(userProfileProvider(user.id));
  return profileAsync.maybeWhen(
    data: (profile) => profile?.role == 'admin',
    orElse: () => false,
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
