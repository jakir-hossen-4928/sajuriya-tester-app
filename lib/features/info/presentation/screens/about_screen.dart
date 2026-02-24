import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Sajuriya'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo / Icon Header
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('asstes/icons/app_icon.png', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sajuriya Tester',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '1.0.0';
                return Text(
                  'Version $version',
                  style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                );
              },
            ),
            const SizedBox(height: 40),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Solving the 12-Tester Block',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sajuriya Tester is a community platform built to help solo developers meet Google Play\'s mandatory 12-tester requirement. We use a "Mutual Help" model—you test apps to earn Karma, and use that Karma to get testers for your own apps.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                    const SizedBox(height: 24),
                    _buildFeatureItem(context, Icons.verified_user, '100% Genuine Testers'),
                    _buildFeatureItem(context, Icons.sync_alt, 'Karma-Based Exchange'),
                    _buildFeatureItem(context, Icons.groups_rounded, 'Google Group Integrated'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            Text(
              'Built with ❤️ for Solo Developers',
              style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
        ],
      ),
    );
  }
}
