import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sajuriyatester/core/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:sajuriyatester/core/services/imgbb_service.dart';
import 'package:sajuriyatester/features/auth/presentation/providers/auth_provider.dart';
import 'package:sajuriyatester/features/profile/data/services/user_data_service.dart';
import 'package:sajuriyatester/core/models/models.dart';
import 'package:sajuriyatester/core/widgets/skeleton_widgets.dart';

final profileServiceProvider = Provider((ref) => ProfileService());

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final imgbb = ImgBBService();
      final url = await imgbb.uploadImage(File(image.path));
      
      if (url != null) {
        await ref.read(profileServiceProvider).updateAvatar(user.id, url);
        ref.invalidate(userProfileProvider(user.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await ref.read(profileServiceProvider).updateProfile(
            userId: user.id,
            fullName: _nameController.text.trim(),
          );
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  Widget _buildInitialAvatar(BuildContext context) {
    final initial = (_nameController.text.isNotEmpty ? _nameController.text : 'U')[0].toUpperCase();
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 40,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider(user?.id ?? '')).maybeWhen(
          data: (admin) => admin,
          orElse: () => false,
        );

    final profileAsync = user != null ? ref.watch(userProfileProvider(user.id)) : null;

    if (profileAsync == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return profileAsync.when(
      skipLoadingOnRefresh: false, // Ensure we see skeleton only when actually loading OR on manual cache refresh
      loading: () => const ProfileSkeleton(),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.signal_wifi_off_outlined, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Connection Issues',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'We are having trouble connecting to the real-time profile service.\n\nDetails: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(userProfileProvider(user!.id)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (profile) {
        final themeMode = ref.watch(themeProvider);
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);

        // Initialize controller if not already set
        if (_nameController.text.isEmpty && profile?.fullName != null) {
          _nameController.text = profile!.fullName!;
        } else if (_nameController.text.isEmpty && user?.userMetadata?['full_name'] != null) {
          _nameController.text = user!.userMetadata!['full_name'];
        }

        // Resolve avatar URL: DB upload → Google metadata picture → null
        final avatarUrl = profile?.avatarUrl?.isNotEmpty == true
            ? profile!.avatarUrl!
            : (user?.userMetadata?['avatar_url'] as String? ??
               user?.userMetadata?['picture'] as String?);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                onPressed: () {
                  if (_isEditing) {
                    _updateProfile();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
                icon: Icon(_isEditing ? Icons.check : Icons.edit_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      ),
                      child: ClipOval(
                        child: avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                width: 110,
                                height: 110,
                                placeholder: (context, url) => Container(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => _buildInitialAvatar(context),
                              )
                            : _buildInitialAvatar(context),
                      ),
                    ),
                    if (_isUploading)
                      Positioned.fill(
                        child: CircularImageSkeleton(size: 110),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          onPressed: _isUploading ? null : _pickAndUploadImage,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_isEditing)
                  TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Full Name'),
                  )
                else
                  Text(
                    _nameController.text.isEmpty ? (profile?.fullName ?? 'Sajuriya Developer') : _nameController.text,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                Text(
                  user?.email ?? 'tester@example.com',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                _buildKarmaCard(context, profile),
                const SizedBox(height: 24),
                _buildMenuItem(
                  context,
                  'My App Listings',
                  Icons.list_alt_outlined,
                  onTap: () => context.push('/my-apps'),
                ),
                if (isAdmin)
                  _buildMenuItem(
                    context,
                    'Admin Panel',
                    Icons.admin_panel_settings_outlined,
                    onTap: () => context.push('/admin'),
                  ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (val) {
                      ref.read(themeProvider.notifier).setTheme(val ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ),
                _buildMenuItem(
                  context, 
                  'Join Google Group', 
                  Icons.groups_outlined,
                  subtitle: 'sajuriya-tester@googlegroups.com',
                  onTap: () async {
                    final url = Uri.parse('https://groups.google.com/g/sajuriya-tester'); // TODO: Update with actual group link
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                const Divider(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('RESOURCES', 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).colorScheme.onSurfaceVariant, 
                        letterSpacing: 1.2
                      )
                    ),
                  ),
                ),
                _buildMenuItem(
                  context,
                  'App Documentation',
                  Icons.description_outlined,
                  onTap: () => context.push('/documentation'),
                ),
                _buildMenuItem(
                  context,
                  'Privacy Policy',
                  Icons.privacy_tip_outlined,
                  onTap: () => context.push('/privacy-policy'),
                ),
                _buildMenuItem(
                  context,
                  'About Sajuriya',
                  Icons.info_outline_rounded,
                  onTap: () => context.push('/about'),
                ),
                _buildMenuItem(
                  context,
                  'Help & Support',
                  Icons.help_outline,
                  onTap: () => context.push('/help-support'),
                ),
                const Divider(height: 32),
                _buildMenuItem(
                  context,
                  'Logout',
                  Icons.logout_outlined,
                  isDestructive: true,
                  onTap: () async {
                    // Capture before async gaps to avoid ref-after-unmount
                    final authService = ref.read(authServiceProvider);
                    await authService.signOut();
                    if (!context.mounted) return;
                    ref.invalidate(userProfileProvider);
                    ref.invalidate(currentUserProvider);
                    context.go('/auth');
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildKarmaCard(BuildContext context, Profile? profile) {
    final karma = profile?.credits ?? 0;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -15,
            child: Icon(
              Icons.stars_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR KARMA',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$karma',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Credits',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => context.push('/wallet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Open Karma Hub',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon, {
    String? subtitle,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : colorScheme.onSurfaceVariant),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.redAccent : colorScheme.onSurface,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: Icon(Icons.chevron_right, size: 20, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
      onTap: onTap,
    );
  }
}
