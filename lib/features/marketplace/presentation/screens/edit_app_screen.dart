import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sajuriyatester/core/models/models.dart';
import 'my_apps_screen.dart';

class EditAppScreen extends ConsumerStatefulWidget {
  final AppModel app;
  const EditAppScreen({super.key, required this.app});

  @override
  ConsumerState<EditAppScreen> createState() => _EditAppScreenState();
}

class _EditAppScreenState extends ConsumerState<EditAppScreen> {
  late TextEditingController _nameController;
  late TextEditingController _packageController;
  late TextEditingController _urlController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.app.appName);
    _packageController = TextEditingController(text: widget.app.packageName);
    _urlController = TextEditingController(text: widget.app.playStoreUrl);
    _descriptionController = TextEditingController(text: widget.app.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _packageController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(appServiceProvider).updateApp(
            appId: widget.app.id,
            appName: _nameController.text.trim(),
            packageName: _packageController.text.trim(),
            playStoreUrl: _urlController.text.trim(),
            description: _descriptionController.text.trim(),
          );
      ref.invalidate(myAppsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit App Listing')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'App Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _packageController,
                decoration: const InputDecoration(labelText: 'Package Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'Play Store URL'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
