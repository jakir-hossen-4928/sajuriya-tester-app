import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sajuriyatester/core/widgets/skeleton_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sajuriyatester/core/models/models.dart';
import '../providers/admin_provider.dart';

class AppManagementScreen extends ConsumerStatefulWidget {
  const AppManagementScreen({super.key});

  @override
  ConsumerState<AppManagementScreen> createState() => _AppManagementScreenState();
}

class _AppManagementScreenState extends ConsumerState<AppManagementScreen> {
  Timer? _debounce;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(adminSearchQueryProvider));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(adminSearchQueryProvider.notifier).setQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(allAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Management'),
        actions: [
          IconButton(
            onPressed: () => ref.read(allAppsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search apps by name or package...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(allAppsProvider.notifier).refresh(),
          child: apps.when(
            data: (data) => data.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text('No apps found.',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: data.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final app = data[index];
                      return _buildAppCard(context, ref, app);
                    },
                  ),
            loading: () => const GenericListSkeleton(),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }

  Widget _buildAppCard(BuildContext context, WidgetRef ref, AppModel app) {
    final status = app.status;
    final isActive = status == 'active';

    Color statusColor = isActive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
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
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: app.appIcon != null 
                    ? DecorationImage(image: NetworkImage(app.appIcon!), fit: BoxFit.cover)
                    : null,
                ),
                child: app.appIcon == null 
                  ? Icon(Icons.apps, color: Theme.of(context).primaryColor)
                  : null,
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
                      '${app.packageName} • by ${app.developer?.fullName ?? 'Unknown'}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (app.playStoreUrl.isNotEmpty)
             Text(
              'Play Store Link: ${app.playStoreUrl}',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _updateAppStatus(
                    context, 
                    ref, 
                    app, 
                    isActive ? 'inactive' : 'active'
                  ),
                  icon: Icon(isActive ? Icons.block : Icons.check_circle),
                  label: Text(isActive ? 'Deactivate' : 'Activate'),
                  style: FilledButton.styleFrom(
                    backgroundColor: isActive ? Colors.red.withValues(alpha: 0.8) : Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showEditDialog(context, ref, app),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Details',
              ),
              IconButton(
                onPressed: () => _showDeleteDialog(context, ref, app),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Permanently',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateAppStatus(BuildContext context, WidgetRef ref, AppModel app, String newStatus) async {
    try {
      await ref.read(adminServiceProvider).updateAppStatus(app.id, newStatus);
      ref.invalidate(allAppsProvider);
      ref.invalidate(adminStatsProvider);
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('App moved to $newStatus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, AppModel app) async {
    final nameController = TextEditingController(text: app.appName);
    final packageController = TextEditingController(text: app.packageName);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit App Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'App Name')),
            TextField(controller: packageController, decoration: const InputDecoration(labelText: 'Package Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(adminServiceProvider).updateAppDetails(app.id, {
        'app_name': nameController.text,
        'package_name': packageController.text,
      });
      ref.invalidate(allAppsProvider);
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref, AppModel app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text('Are you sure you want to delete "${app.appName}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(adminServiceProvider).removeApp(app.id);
      ref.invalidate(allAppsProvider);
      ref.invalidate(adminStatsProvider);
    }
  }
}
