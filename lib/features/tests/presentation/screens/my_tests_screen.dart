import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sajuriyatester/core/utils/app_checker.dart';
import 'package:sajuriyatester/features/auth/presentation/providers/auth_provider.dart';
import 'package:sajuriyatester/features/tests/data/services/test_service.dart';
import 'package:sajuriyatester/features/profile/presentation/providers/karma_provider.dart';
import 'package:sajuriyatester/core/models/models.dart';
import 'package:sajuriyatester/core/widgets/image_widgets.dart';
import 'package:sajuriyatester/core/widgets/skeleton_widgets.dart';

import 'package:sajuriyatester/core/providers/common_providers.dart';

final testServiceProvider = Provider((ref) => TestService());

final activeTestsProvider = AsyncNotifierProvider<ActiveTestsNotifier, List<TestAssignment>>(() {
  return ActiveTestsNotifier();
});

class ActiveTestsNotifier extends AsyncNotifier<List<TestAssignment>> {
  @override
  FutureOr<List<TestAssignment>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    
    ref.keepAlive();
    final cache = ref.read(localCacheServiceProvider);
    
    final cached = await cache.getActiveTests();
    
    if (cached.isEmpty) {
      return _fetchFromNetwork();
    }
    
    _fetchFromNetwork();
    return cached;
  }

  Future<List<TestAssignment>> _fetchFromNetwork() async {
    final userId = ref.read(currentUserProvider.select((u) => u?.id));
    if (userId == null) return [];
    
    try {
      final response = await ref.read(testServiceProvider).getActiveAssignments(userId);
      await ref.read(localCacheServiceProvider).saveActiveTests(response);
      state = AsyncData(response);
      return response;
    } catch (e) {
      debugPrint('[ActiveTests] Background sync failed: $e');
      if (state.hasValue) return state.value!;
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _fetchFromNetwork();
  }
}

final completedTestsProvider = AsyncNotifierProvider<CompletedTestsNotifier, List<TestAssignment>>(() {
  return CompletedTestsNotifier();
});

class CompletedTestsNotifier extends AsyncNotifier<List<TestAssignment>> {
  @override
  FutureOr<List<TestAssignment>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    ref.keepAlive();
    final cache = ref.read(localCacheServiceProvider);
    
    final cached = await cache.getCompletedTests();
    
    if (cached.isEmpty) {
      return _fetchFromNetwork();
    }
    
    _fetchFromNetwork();
    return cached;
  }

  Future<List<TestAssignment>> _fetchFromNetwork() async {
    final userId = ref.read(currentUserProvider.select((u) => u?.id));
    if (userId == null) return [];
    
    try {
      final response = await ref.read(testServiceProvider).getCompletedAssignments(userId);
      await ref.read(localCacheServiceProvider).saveCompletedTests(response);
      state = AsyncData(response);
      return response;
    } catch (e) {
      debugPrint('[CompletedTests] Background sync failed: $e');
      if (state.hasValue) return state.value!;
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _fetchFromNetwork();
  }
}

/// Returns true if the current user already has a test assignment
/// (active or completed) for the given [appId].
/// Optimized to use cached local data from active/completed providers.
final userTestStatusProvider = Provider.family<AsyncValue<bool>, String>((ref, appId) {
  final activeAsync = ref.watch(activeTestsProvider);
  final completedAsync = ref.watch(completedTestsProvider);

  if (activeAsync is AsyncData && completedAsync is AsyncData) {
    final activeIds = activeAsync.value!.map((e) => e.appId).toSet();
    final completedIds = completedAsync.value!.map((e) => e.appId).toSet();
    return AsyncValue.data(activeIds.contains(appId) || completedIds.contains(appId));
  }
  
  if (activeAsync is AsyncLoading || completedAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }
  
  if (activeAsync is AsyncError) return AsyncValue.error(activeAsync.error!, activeAsync.stackTrace!);
  if (completedAsync is AsyncError) return AsyncValue.error(completedAsync.error!, completedAsync.stackTrace!);

  return const AsyncValue.data(false);
});

class MyTestsScreen extends ConsumerStatefulWidget {
  const MyTestsScreen({super.key});

  @override
  ConsumerState<MyTestsScreen> createState() => _MyTestsScreenState();
}

class _MyTestsScreenState extends ConsumerState<MyTestsScreen> {
  bool _isVerifying = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'My Testing Tasks',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          elevation: 0,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.titleTextStyle?.color,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                ],
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildWarningBanner(),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTestList(ref.watch(activeTestsProvider), isActive: true),
                    _buildTestList(ref.watch(completedTestsProvider), isActive: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Important Requirement',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure you\'re using the same email on Play Store that you used join our Testing Group.',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                final url = Uri.parse('https://groups.google.com/g/sajuriya-tester');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.group_add_outlined, size: 18),
              label: const Text('Join Google Testing Group'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestList(AsyncValue<List<TestAssignment>> tests, {required bool isActive}) {
    return RefreshIndicator(
      onRefresh: () async {
        if (isActive) {
          await ref.read(activeTestsProvider.notifier).refresh();
        } else {
          await ref.read(completedTestsProvider.notifier).refresh();
        }
      },
      child: tests.when(
        data: (data) => data.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isActive ? Icons.document_scanner_outlined : Icons.assignment_turned_in_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isActive ? 'No active testing tasks' : 'No tests completed yet',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isActive ? 'Start picking apps from the marketplace' : 'Your completed tests will appear here',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                itemCount: data.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final assignment = data[index];
                  return _buildTestCard(assignment, isActive);
                },
              ),
        loading: () => const TestListSkeleton(),
        error: (e, s) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: Text('Error: $e'),
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard(TestAssignment assignment, bool isActive) {
    if (isActive) return _buildActiveCard(assignment);
    return _buildCompletedCard(assignment);
  }

  Widget _buildActiveCard(TestAssignment assignment) {
    final app = assignment.app;
    final reward = app?.rewardCredits ?? 10;
    
    final requiredDays = app?.requiredTestDays ?? 14;
    final daysElapsed = DateTime.now().difference(assignment.startDate).inDays;
    final progress = daysElapsed / requiredDays;
    final canVerify = daysElapsed >= requiredDays;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (app != null) context.push('/app-details', extra: app);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppIconWidget(imageUrl: app?.appIcon, size: 56),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app?.appName ?? 'Unknown App',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            app?.packageName ?? '',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.indigo, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$reward',
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Testing Progress (${daysElapsed}d / ${requiredDays}d)',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[100],
                    minHeight: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? Colors.green : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isVerifying || !canVerify) ? null : () => _handleTestCompletion(assignment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canVerify ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                      foregroundColor: canVerify ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: canVerify ? Theme.of(context).primaryColor.withValues(alpha: 0.5) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                      disabledForegroundColor: canVerify ? Colors.white.withValues(alpha: 0.7) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            canVerify ? 'Verify & Collect Karma' : 'Wait ${requiredDays - daysElapsed} more days',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedCard(TestAssignment assignment) {
    final app = assignment.app;
    final reward = app?.rewardCredits ?? 10;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AppIconWidget(
              imageUrl: app?.appIcon,
              size: 50,
              backgroundColor: Colors.green.withValues(alpha: 0.05),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app?.appName ?? 'Unknown App',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade400, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Verified & Credited',
                        style: TextStyle(color: Colors.green.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+$reward',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Karma',
                  style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTestCompletion(TestAssignment assignment) async {
    if (_isVerifying) return; // Prevent double-taps
    
    // Capture messenger before any async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _isVerifying = true);

    try {
      // 1. Check if eligible (days passed)
      final requiredDays = assignment.app?.requiredTestDays ?? 14;
      final daysElapsed = DateTime.now().difference(assignment.startDate).inDays;
      if (daysElapsed < requiredDays) {
        throw 'You must test the app for at least $requiredDays days before verifying. Only $daysElapsed days have passed.';
      }

      // 2. Check if App is installed
      final packageName = assignment.app?.packageName;
      if (packageName == null) throw 'App package name is missing';

      final bool isInstalled = await AppChecker.isAppInstalled(packageName);

      if (!isInstalled) {
        if (mounted) _showInstallAlert(assignment.app!);
        return;
      }

      // 2. Launch the app as proof of installation
      final appUri = Uri.parse('android-app://$packageName');
      final launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);
      
      if (!launched) {
        // Fallback: try launching via Play Store intent
        final fallbackUri = Uri.parse('market://details?id=$packageName');
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }

      // Small delay to let the app open before we complete in background
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Complete Testing via RPC
      await ref.read(karmaServiceProvider).completeTesting(
            assignment.id,
            'device_verified',
          );

      final userId = ref.read(currentUserProvider)?.id;
      if (userId != null) {
        ref.invalidate(activeTestsProvider);
        ref.invalidate(completedTestsProvider);
        ref.invalidate(userProfileProvider(userId));
        ref.invalidate(transactionHistoryProvider);
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('✅ App launched & verified! Karma rewarded.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showInstallAlert(AppModel app) {
    final tutorialUrl = const String.fromEnvironment(
      'YOUTUBE_TRUTORIAL',
      defaultValue: '',
    ).isEmpty
        ? dotenv.env['YOUTUBE_TRUTORIAL'] ?? ''
        : const String.fromEnvironment('YOUTUBE_TRUTORIAL');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Item Not Found image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'asstes/icons/item-not-found.jpg',
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              '⚠️ App Not Visible in Play Store?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Explanation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Text(
                'This app is only available to internal testers.\n\n'
                'You need to join our Google Testing Group first, then wait a few minutes before the app appears in the Play Store.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),

            // YouTube tutorial button
            if (tutorialUrl.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(tutorialUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.play_circle_outline, color: Colors.red),
                  label: const Text('Watch Tutorial on YouTube'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const SizedBox(height: 10),

            // Open Play Store button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(app.playStoreUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.store),
                label: const Text('Open Play Store'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Dismiss button
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }
}
