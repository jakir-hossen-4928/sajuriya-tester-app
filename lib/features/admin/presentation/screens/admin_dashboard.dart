import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import 'package:sajuriyatester/core/widgets/skeleton_widgets.dart';

final pendingCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(adminServiceProvider).getPendingCounts();
});

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    final pending = ref.watch(pendingCountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(adminStatsProvider);
              ref.invalidate(pendingCountsProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(pendingCountsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              stats.when(
                data: (data) => _buildStatGrid(context, data),
                loading: () => const AdminStatsSkeleton(),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
              const SizedBox(height: 32),
              const Text(
                'Management',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                context,
                title: 'App Management',
                subtitle: 'Manage and de-active app listings',
                icon: Icons.rocket_launch_outlined,
                color: Colors.orange,
                onTap: () => context.push('/admin/apps'),
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                context, 
                title: 'User Management',
                subtitle: 'Control credits, roles & access',
                icon: Icons.people_outline,
                color: Colors.purple,
                onTap: () => context.push('/admin/users'),
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                context,
                title: 'Test Verification',
                subtitle: 'Verify completed test proofs',
                icon: Icons.fact_check_outlined,
                color: Colors.blue,
                count: pending.when(
                  data: (p) => p['completedTests']! > 0 ? p['completedTests'].toString() : null,
                  loading: () => null,
                  error: (e, s) => null,
                ),
                onTap: () {}, // Future implementation
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStatGrid(BuildContext context, Map<String, dynamic> data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(context, 'Total Users', data['totalUsers'].toString(), Icons.people_outline),
        _buildStatCard(context, 'Active Apps', data['activeApps'].toString(), Icons.rocket_launch_outlined),
        _buildStatCard(context, 'Tests Done', data['completedTests'].toString(), Icons.check_circle_outline),
        _buildStatCard(context, 'Total Karma', data['totalKarma'].toString(), Icons.stars_rounded),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? count,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  count,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
