import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sajuriyatester/core/services/imgbb_service.dart';
import 'package:sajuriyatester/features/auth/presentation/providers/auth_provider.dart';
import 'package:sajuriyatester/features/marketplace/presentation/screens/my_apps_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AddAppScreen extends ConsumerStatefulWidget {
  const AddAppScreen({super.key});

  @override
  ConsumerState<AddAppScreen> createState() => _AddAppScreenState();
}

class _AddAppScreenState extends ConsumerState<AddAppScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _packageController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _iconFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    final url = _urlController.text.trim();
    if (url.contains('id=')) {
      final package = url.split('id=').last.split('&').first;
      if (package.isNotEmpty && _packageController.text != package) {
        setState(() {
          _packageController.text = package;
        });
      }
    }
  }

  Future<void> _pickIcon() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _iconFile = File(image.path));
    }
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
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Pre-check credits locally from the profile provider
    final profile = ref.read(userProfileProvider(user.id)).value;
    final currentCredits = profile?.credits ?? 0;

    if (currentCredits < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient Karma! You need 10 credits to list an app. You only have $currentCredits.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_iconFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an app icon')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Upload Icon to ImgBB
      final imgbb = ImgBBService();
      final logoUrl = await imgbb.uploadImage(_iconFile!);
      if (logoUrl == null) throw 'Failed to upload icon';

      // 2. Create Listing (This will call the RPC and fail server-side if credits are < 10)
      await ref.read(appServiceProvider).createAppListing(
            developerId: user.id,
            appName: _nameController.text.trim(),
            packageName: _packageController.text.trim(),
            playStoreUrl: _urlController.text.trim(),
            logoUrl: logoUrl,
            description: _descriptionController.text.trim(),
          );
      
      // Invalidate providers to refresh UI
      ref.invalidate(myAppsProvider);
      ref.invalidate(userProfileProvider(user.id));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Success! App listed and 10 Karma deducted.'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Insufficient Credits')) {
        errorMessage = 'Listing failed: You need at least 10 Karma credits.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List New App'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.checklist_rtl_rounded, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            'Play Console Checklist',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCheckItem('Join Community Google Group (Required)'),
                      _buildCheckItem('Add Group to "Closed Testing" in Play Console'),
                      _buildCheckItem('Select "ALL COUNTRIES" in Testing track'),
                      _buildCheckItem('Ensure "Testers can join" is enabled'),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final url = Uri.parse('https://groups.google.com/g/sajuriya-tester');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.group_add_outlined),
                          label: const Text('Join Community Group'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'App Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'App Name',
                    hintText: 'e.g. Fitness Tracker Pro',
                    prefixIcon: Icon(Icons.drive_file_rename_outline),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _packageController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Package Name',
                    hintText: 'Auto-extracted from URL',
                    prefixIcon: const Icon(Icons.code),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    helperText: 'This will be automatically filled when you paste the Play Store URL.',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Please paste a valid Play Store URL first' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your app and testing requirements...',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Icon',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickIcon,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      image: _iconFile != null 
                          ? DecorationImage(image: FileImage(_iconFile!), fit: BoxFit.cover) 
                          : null,
                    ),
                    child: _iconFile == null 
                        ? Icon(Icons.add_a_photo_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant) 
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Play Store URL',
                    hintText: 'https://play.google.com/store/apps/details?id=...',
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Play Store URL is required';
                    if (!v.contains('id=')) return 'Invalid Play Store URL (missing package ID)';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // Credit Cost Section
                Consumer(builder: (context, ref, child) {
                  final user = ref.watch(currentUserProvider);
                  final profile = user != null ? ref.watch(userProfileProvider(user.id)).value : null;
                  final credits = profile?.credits ?? 0;
                  final canAfford = credits >= 10;
                  
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: canAfford 
                          ? Colors.green.withValues(alpha: 0.05) 
                          : Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: canAfford 
                            ? Colors.green.withValues(alpha: 0.2) 
                            : Colors.red.withValues(alpha: 0.2)
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Listing Cost:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const Text('10 Karma', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Your Balance:', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text('$credits Karma', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: canAfford ? Colors.green : Colors.red
                              )
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Confirm & Deduct 10 Karma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
