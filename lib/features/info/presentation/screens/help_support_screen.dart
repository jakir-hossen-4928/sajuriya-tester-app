import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.radar_rounded,
                  size: 50,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Sajuriya',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Center(
              child: Text(
                'Closed Testing Community',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildAboutCard(
              context,
              'Our Mission',
              'Connecting developers with real testers to fulfill Google Play\'s 20-tester requirement, fostering a community of mutual growth and support.',
              Icons.rocket_launch_rounded,
            ),
            _buildAboutCard(
              context,
              'How it Works',
              'Developers list their apps, and community members join as testers. In return, testers earn Karma which they can use to list their own apps.',
              Icons.loop_rounded,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Common Resources'),
            const SizedBox(height: 12),
            _buildSupportCard(
              context,
              icon: Icons.groups_rounded,
              title: 'Community Group',
              subtitle: 'Join our Google Group to discuss and get help.',
              onTap: () => _launchURL('https://groups.google.com/g/sajuriya-tester'),
            ),
            const SizedBox(height: 12),
            _buildSupportCard(
              context,
              icon: Icons.description_rounded,
              title: 'Documentation',
              subtitle: 'Read our guides on setting up your Play Console.',
              onTap: () => _launchURL('https://sajuriya-tester.web.app/docs'), // Placeholder for web docs
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Contact Us'),
            const SizedBox(height: 12),
            _buildSupportCard(
              context,
              icon: Icons.email_rounded,
              title: 'Email Support',
              subtitle: 'Direct support for account or payment issues.',
              onTap: () => _launchEmail('mdjakirkhan4928@gmail.com'),
            ),
            const SizedBox(height: 12),
            _buildSupportCard(
              context,
              icon: Icons.chat_bubble_rounded,
              title: 'Telegram Support',
              subtitle: 'Fastest way to get help from our team.',
              onTap: () => _launchURL('https://t.me/jakirhossen4928'),
            ),
            const SizedBox(height: 48),
            Center(
              child: Opacity(
                opacity: 0.6,
                child: Column(
                  children: [
                    Icon(Icons.support_agent_rounded, size: 48, color: colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Our team usually responds within 24 hours.',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '1.0.0';
                return Center(
                  child: Text(
                    'Version $version',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support Request - Sajuriya Tester',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
