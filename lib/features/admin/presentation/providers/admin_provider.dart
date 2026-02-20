import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/models.dart';
import '../../data/services/admin_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final adminServiceProvider = Provider((ref) => AdminService());

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(adminServiceProvider).getStats();
});

final adminSearchQueryProvider = NotifierProvider<AdminSearchNotifier, String>(() {
  return AdminSearchNotifier();
});

class AdminSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
}

final allUsersProvider = AsyncNotifierProvider<AdminUsersNotifier, List<Profile>>(() {
  return AdminUsersNotifier();
});

class AdminUsersNotifier extends AsyncNotifier<List<Profile>> {
  @override
  FutureOr<List<Profile>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    
    final query = ref.watch(adminSearchQueryProvider);
    return _fetch(query);
  }

  Future<List<Profile>> _fetch(String query) async {
    return ref.read(adminServiceProvider).getAllUsers(query: query);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(ref.read(adminSearchQueryProvider)));
  }
}

final allAppsProvider = AsyncNotifierProvider<AdminAppsNotifier, List<AppModel>>(() {
  return AdminAppsNotifier();
});

class AdminAppsNotifier extends AsyncNotifier<List<AppModel>> {
  @override
  FutureOr<List<AppModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    
    final query = ref.watch(adminSearchQueryProvider);
    return _fetch(query);
  }

  Future<List<AppModel>> _fetch(String query) async {
    return ref.read(adminServiceProvider).getAllApps(query: query);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(ref.read(adminSearchQueryProvider)));
  }
}

