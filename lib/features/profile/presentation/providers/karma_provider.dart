import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sajuriyatester/features/auth/presentation/providers/auth_provider.dart';
import 'package:sajuriyatester/core/providers/common_providers.dart';
import '../../../../core/models/models.dart';
import '../../data/services/user_data_service.dart';

final karmaServiceProvider = Provider((ref) => KarmaService());

final transactionHistoryProvider = AsyncNotifierProvider<TransactionHistoryNotifier, List<KarmaTransaction>>(() {
  return TransactionHistoryNotifier();
});

class TransactionHistoryNotifier extends AsyncNotifier<List<KarmaTransaction>> {
  @override
  FutureOr<List<KarmaTransaction>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    ref.keepAlive();
    final cache = ref.read(localCacheServiceProvider);
    
    final cached = await cache.getTransactions();
    
    if (cached.isEmpty) {
      return _fetchFromNetwork();
    }
    
    _fetchFromNetwork();
    return cached;
  }

  Future<List<KarmaTransaction>> _fetchFromNetwork() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return [];
    
    try {
      final response = await ref.read(karmaServiceProvider).getTransactionHistory(user.id);
      await ref.read(localCacheServiceProvider).saveTransactions(response);
      state = AsyncData(response);
      return response;
    } catch (e) {
      debugPrint('[Transactions] Background sync failed: $e');
      if (state.hasValue) return state.value!;
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _fetchFromNetwork();
  }
}
