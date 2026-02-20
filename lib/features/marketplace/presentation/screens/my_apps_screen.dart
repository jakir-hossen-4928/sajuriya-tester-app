import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sajuriyatester/features/auth/presentation/providers/auth_provider.dart';
import 'package:sajuriyatester/features/profile/data/services/user_data_service.dart';
import 'package:sajuriyatester/core/models/models.dart';
import 'package:sajuriyatester/core/widgets/skeleton_widgets.dart';
import 'package:sajuriyatester/core/providers/common_providers.dart';

final appServiceProvider = Provider((ref) => AppService());

final myAppsProvider = AsyncNotifierProvider<MyAppsNotifier, List<AppModel>>(() {
  return MyAppsNotifier();
});

class MyAppsNotifier extends AsyncNotifier<List<AppModel>> {
  @override
  FutureOr<List<AppModel>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    
    ref.keepAlive();
    final cache = ref.read(localCacheServiceProvider);
    
    final cached = await cache.getMyApps();
    
    if (cached.isEmpty) {
      return _fetchFromNetwork();
    }
    
    _fetchFromNetwork();
    return cached;
  }

  Future<List<AppModel>> _fetchFromNetwork() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return [];
    
    try {
      final response = await ref.read(appServiceProvider).getDeveloperApps(user.id);
      await ref.read(localCacheServiceProvider).saveMyApps(response);
      state = AsyncData(response);
      return response;
    } catch (e) {
      debugPrint('[MyApps] Background sync failed: $e');
      if (state.hasValue) return state.value!;
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _fetchFromNetwork();
  }
}

class MyAppsScreen extends ConsumerWidget {
  const MyAppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myApps = ref.watch(myAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My App Listings'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(myAppsProvider.notifier).refresh(),
        child: myApps.when(
          data: (apps) {
            if (apps.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apps_outage_outlined, size: 80, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                      const SizedBox(height: 24),
                      Text('You haven\'t listed any apps yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text('Help the community by testing others and listing your own!', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13)),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              itemCount: apps.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final app = apps[index];
                return _buildAppItem(context, ref, app);
              },
            );
          },
          loading: () => const MyAppsListSkeleton(),
          error: (e, s) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              alignment: Alignment.center,
              child: Text('Error: $e'),
            ),
          ),
        ),
      ),
    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final user = ref.read(currentUserProvider);
          if (user == null) return;
          
          final profile = ref.read(userProfileProvider(user.id)).value;
          final credits = profile?.credits ?? 0;
          
          if (credits < 10) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Insufficient Karma! You need 10 credits to list an app (Balance: $credits).'),
                backgroundColor: Colors.redAccent,
                action: SnackBarAction(
                  label: 'Earn Credits',
                  textColor: Colors.white,
                  onPressed: () => context.go('/marketplace'),
                ),
              ),
            );
            return;
          }
          
          context.push('/add-app');
        },
        icon: const Icon(Icons.add),
        label: const Text('List New App'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAppItem(BuildContext context, WidgetRef ref, AppModel app) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: app.appIcon != null && app.appIcon!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: app.appIcon!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const ImageSkeleton(size: 50, borderRadius: 12),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.apps, color: Colors.indigo),
                        )
                      : const Icon(Icons.apps, color: Colors.indigo),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.appName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      app.packageName,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  app.status.toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.green.withValues(alpha: 0.05),
                side: BorderSide(color: Colors.green.withValues(alpha: 0.2)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/edit-app', extra: app);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete App?'),
                      content: const Text('Are you sure you want to remove this listing?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(appServiceProvider).deleteApp(app.id);
                    ref.invalidate(myAppsProvider);
                  }
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
