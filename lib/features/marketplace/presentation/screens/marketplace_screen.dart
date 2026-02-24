import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sajuriyatester/core/widgets/image_widgets.dart';
import 'package:sajuriyatester/core/widgets/skeleton_widgets.dart';
import 'package:sajuriyatester/features/auth/presentation/providers/auth_provider.dart';
import 'package:sajuriyatester/core/config/supabase_config.dart';
import 'package:sajuriyatester/features/tests/presentation/screens/my_tests_screen.dart';
import 'package:sajuriyatester/core/models/app_model.dart';
import 'package:sajuriyatester/core/models/profile_model.dart';
import 'package:sajuriyatester/core/models/karma_transaction_model.dart';
import 'package:sajuriyatester/core/models/test_assignment_model.dart';
import 'package:sajuriyatester/core/providers/common_providers.dart';

final marketplaceAppsProvider = AsyncNotifierProvider<MarketplaceNotifier, List<AppModel>>(() {
  return MarketplaceNotifier();
});

class MarketplaceNotifier extends AsyncNotifier<List<AppModel>> {
  @override
  FutureOr<List<AppModel>> build() async {
    ref.keepAlive();
    final cache = ref.read(localCacheServiceProvider);
    
    final cached = await cache.getMarketplaceApps();
    
    if (cached.isEmpty) {
      // If cache is empty, we must wait for network to avoid showing "No Apps" prematurely
      return _fetchFromNetwork();
    }
    
    // If we have data, show it instantly and update in background
    _fetchFromNetwork();
    return cached;
  }

  Future<List<AppModel>> _fetchFromNetwork() async {
    final cache = ref.read(localCacheServiceProvider);
    try {
      debugPrint('[Marketplace] Background sync checking for updates...');
      final response = await SupabaseConfig.client
          .from('apps')
          .select('*, profiles(*), test_assignments(is_completed)')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final apps = (response as List).map((e) {
        try {
          final Map<String, dynamic> data = Map<String, dynamic>.from(e);
          // Calculate active testers (those who have NOT completed yet)
          final assignments = data['test_assignments'] as List?;
          final count = assignments?.where((a) => a['is_completed'] == false).length ?? 0;
          data['active_testers_count'] = count;
          return AppModel.fromMap(data);
        } catch (e) {
          debugPrint('[Marketplace] Error parsing app ${e}');
          return null;
        }
      }).whereType<AppModel>().toList();

      await cache.saveMarketplaceApps(apps);
      state = AsyncData(apps);
      return apps;
    } catch (e) {
      debugPrint('[Marketplace] Background sync failed: $e');
      if (state.hasValue) return state.value!;
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _fetchFromNetwork();
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final filteredAppsProvider = Provider<AsyncValue<List<AppModel>>>((ref) {
  final appsAsync = ref.watch(marketplaceAppsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return appsAsync.whenData((apps) {
    if (query.isEmpty) return apps;
    return apps.where((app) {
      final name = app.appName.toLowerCase();
      final dev = (app.developer?.fullName ?? '').toLowerCase();
      return name.contains(query) || dev.contains(query);
    }).toList();
  });
});

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAppsAsync = ref.watch(filteredAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Marketplace'),
      ),
      body: SafeArea(
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).setQuery(value),
              decoration: InputDecoration(
                hintText: 'Search apps or developers...',
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
                suffixIcon: ref.watch(searchQueryProvider).isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () =>
                            ref.read(searchQueryProvider.notifier).setQuery(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.read(marketplaceAppsProvider.notifier).refresh(),
              child: filteredAppsAsync.when(
                data: (apps) {
                  if (apps.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 80, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                              const SizedBox(height: 24),
                              Text(
                                ref.read(searchQueryProvider).isEmpty
                                    ? 'No apps available for testing right now.'
                                    : 'No apps found matching "${ref.read(searchQueryProvider)}"',
                                style: GoogleFonts.poppins(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68, // Increased height to prevent overflow
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return _buildAppCard(context, ref, app);
                    },
                  );
                },
                loading: () => const MarketplaceGridSkeleton(),
                error: (e, s) => ListView(
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.2),
                    Center(child: Text('Error: $e')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildAppCard(BuildContext context, WidgetRef ref, AppModel app) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwnApp = currentUser?.id == app.developerId;

    // Disable button if user already has any assignment for this app
    final alreadyTestedAsync = ref.watch(userTestStatusProvider(app.id));
    final alreadyTested = alreadyTestedAsync.value ?? false;

    final isDisabled = isOwnApp || alreadyTested;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/app-details', extra: app),
        child: Container(
          padding: const EdgeInsets.all(16), // Reduced padding to save space
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
            color: Theme.of(context).colorScheme.surfaceContainerLow, // Use distinct surface color
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'app-icon-${app.id}',
                child: AppIconWidget(
                  imageUrl: app.appIcon,
                  size: 50,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                app.appName,
                style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                app.developer?.fullName ?? 'Developer',
                style: TextStyle(
                  fontSize: 12, 
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                   Icon(Icons.people_alt_rounded,
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${(app.activeTesters ?? 0) + (app.completedTesters ?? 0)} total testers',
                    style: TextStyle(
                      fontSize: 11, 
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.stars_rounded,
                      color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${app.rewardCredits} Karma',
                    style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  onPressed: isDisabled
                      ? null
                      : () => _handleStartTesting(context, ref, app),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor:
                        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                  child: isDisabled
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOwnApp
                                  ? Icons.person_outline
                                  : Icons.check_circle_outline,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOwnApp ? 'Your App' : 'Already Testing',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        )
                      : const Text('Start Test',
                          style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleStartTesting(
      BuildContext context, WidgetRef ref, AppModel app) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (user.id == app.developerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot test your own app!')),
      );
      return;
    }

    try {
      await ref.read(testServiceProvider).startTesting(user.id, app.id);
      ref.invalidate(activeTestsProvider);
      // Invalidate the status cache so the button updates immediately
      ref.invalidate(userTestStatusProvider(app.id));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Test assigned! Go to "My Testing" to complete it.')),
        );
        context.push('/app-details', extra: app);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
