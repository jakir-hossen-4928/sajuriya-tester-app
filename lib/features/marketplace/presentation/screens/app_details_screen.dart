import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sajuriyatester/core/utils/app_checker.dart';
import 'package:sajuriyatester/core/widgets/image_widgets.dart';
import 'package:sajuriyatester/features/auth/presentation/providers/auth_provider.dart';
import 'package:sajuriyatester/features/tests/presentation/screens/my_tests_screen.dart';
import 'package:sajuriyatester/core/models/models.dart';

class AppDetailsScreen extends ConsumerStatefulWidget {
  final AppModel app;
  const AppDetailsScreen({super.key, required this.app});

  @override
  ConsumerState<AppDetailsScreen> createState() => _AppDetailsScreenState();
}

class _AppDetailsScreenState extends ConsumerState<AppDetailsScreen> {
  bool _isChecking = false;
  bool _storeOpened = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDeveloper = user?.id == widget.app.developerId;

    // Check if user already has a test assignment for this app
    final alreadyTestedAsync = ref.watch(userTestStatusProvider(widget.app.id));
    final alreadyTested = alreadyTestedAsync.value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Row(
                children: [
                  Hero(
                    tag: 'app-icon-${widget.app.id}',
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AppIconWidget(
                          imageUrl: widget.app.appIcon,
                          size: 80,
                          borderRadius: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.app.appName,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.app.developer?.fullName ?? 'Developer',
                          style:
                              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.app.rewardCredits} Karma Reward',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.app.description ??
                        'No description provided by the developer.',
                    style: TextStyle(
                        fontSize: 15, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Technical Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoTile(
                      Icons.code, 'Package Name', widget.app.packageName),
                  _buildInfoTile(
                      Icons.api, 'Status', widget.app.status.toUpperCase()),

                  const SizedBox(height: 40),

                  if (isDeveloper) ...[
                    const Center(
                      child: Text(
                        'This is your own app listing.',
                        style: TextStyle(
                            color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ] else if (alreadyTested) ...[
                    // ── Already enrolled banner ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 28),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Already in Testing',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'You have already enrolled in testing this app. '
                                  'Go to "My Testing" to track your progress.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green,
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: null, // disabled – already enrolled
                        icon: const Icon(Icons.block_rounded),
                        label: const Text(
                          'Already Testing This App',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          disabledBackgroundColor:
                              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                          disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                    ),
                  ] else ...[
                    // ── Normal enrolment flow ──
                    if (!_storeOpened)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _handleOpenPlayStore(),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Download & Test Now',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.green),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Opened Play Store. Please install the app and come back to verify.',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isChecking ? null : () => _verifyAndStart(),
                              icon: _isChecking
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.verified_user_outlined),
                              label: Text(_isChecking
                                  ? 'Checking...'
                                  : 'Verify Installation'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _handleOpenPlayStore(),
                            child: const Text('Open Play Store Again'),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOpenPlayStore() async {
    final url = widget.app.playStoreUrl;
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      setState(() => _storeOpened = true);
    }
  }

  Future<void> _verifyAndStart() async {
    final packageName = widget.app.packageName;
    if (packageName.isEmpty) return;

    setState(() => _isChecking = true);
    try {
      final isInstalled = await AppChecker.isAppInstalled(packageName);
      if (isInstalled == true) {
        await _handleStartTesting();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'App not found on device. Please install it first.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _handleStartTesting() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await ref.read(testServiceProvider).startTesting(user.id, widget.app.id);
      ref.invalidate(activeTestsProvider);
      // Invalidate status so the button updates immediately
      ref.invalidate(userTestStatusProvider(widget.app.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App verified and test assigned!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
