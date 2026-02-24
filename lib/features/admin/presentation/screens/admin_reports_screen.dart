import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'dart:convert';
import 'dart:async';
import 'package:sajuriyatester/core/providers/common_providers.dart';

final adminReportsProvider = AsyncNotifierProvider<AdminReportsNotifier, List<Map<String, dynamic>>>(() {
  return AdminReportsNotifier();
});

class AdminReportsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  static const _cacheKey = 'admin_reports_cache';

  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final cacheService = ref.watch(localCacheServiceProvider);
    
    // 1. Try to load from cache first
    final cachedData = await cacheService.getString(_cacheKey);
    if (cachedData != null) {
      try {
        final decoded = jsonDecode(cachedData) as List;
        final list = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        
        // 2. Fetch fresh data in the background
        _fetchAndCache();
        
        return list;
      } catch (e) {
        // Cache is invalid, proceed to fetch
      }
    }

    // 3. Fallback to normal fetch if no valid cache
    return _fetchAndCache();
  }

  Future<List<Map<String, dynamic>>> _fetchAndCache() async {
    try {
      final db = Supabase.instance.client;
      final response = await db
          .from('app_reports')
          .select('*, app:apps(app_name, package_name), reporter:profiles(full_name, email)')
          .order('created_at', ascending: false);
          
      final list = List<Map<String, dynamic>>.from(response);
      
      // Save to cache
      final cacheService = ref.read(localCacheServiceProvider);
      await cacheService.saveString(_cacheKey, jsonEncode(list));
      
      state = AsyncValue.data(list);
      return list;
    } catch (e) {
      // If we fail fetching and already have data, don't throw, just keep state.
      // If we don't have data, then throw to show the error state.
      if (state.hasValue && state.value!.isNotEmpty) {
        return state.value!;
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      await _fetchAndCache();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Reports Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminReportsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(child: Text('No reports found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final app = report['app'] ?? {};
              final reporter = report['reporter'] ?? {};
              
              final status = report['status'] ?? 'pending';
              Color statusColor = Colors.orange;
              if (status == 'resolved') statusColor = Colors.green;
              if (status == 'rejected') statusColor = Colors.red;

              final createdAt = DateTime.tryParse(report['created_at']) ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'App: ${app['app_name'] ?? 'Unknown'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Reporter: ${reporter['full_name'] ?? 'Unknown'} (${reporter['email'] ?? 'No email'})',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('Date: ${DateFormat('MMM dd, yyyy HH:mm').format(createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall),
                      const Divider(height: 24),
                      Text('Reason: ${report['reason']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Details: ${report['details'] ?? 'No additional details provided.'}'),
                      if (report['image_urls'] != null && (report['image_urls'] as List).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Attached Images:', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: (report['image_urls'] as List).length,
                            itemBuilder: (context, imgIndex) {
                              final imgUrl = report['image_urls'][imgIndex];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imgUrl,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      height: 100,
                                      width: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (status == 'pending' || status == 'reviewed') ...[
                            OutlinedButton(
                              onPressed: () => _updateStatus(context, ref, report['id'], 'resolved'),
                              child: const Text('Mark Resolved'),
                            ),
                            OutlinedButton(
                              onPressed: () => _updateStatus(context, ref, report['id'], 'rejected'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Reject'),
                            ),
                          ] else ...[
                            OutlinedButton(
                              onPressed: () => _updateStatus(context, ref, report['id'], 'pending'),
                              child: const Text('Re-open'),
                            ),
                          ]
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error loading reports', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(adminReportsProvider),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String id, String status) async {
    try {
      await Supabase.instance.client
          .from('app_reports')
          .update({'status': status})
          .eq('id', id);
      
      await ref.read(adminReportsProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report marked as $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }
}
