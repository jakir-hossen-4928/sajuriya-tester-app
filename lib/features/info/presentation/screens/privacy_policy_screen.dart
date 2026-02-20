import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String privacyContent = """
# Privacy Policy

**Effective Date:** February 19, 2026

Welcome to **Sajuriya Tester**. We are committed to protecting your personal data and your privacy. This policy explains how we handle your information.

## 1. Information We Collect
*   **Google Account Data**: When you sign in via Google, we collect your email, full name, and profile picture URL to create your profile.
*   **Device Verification**: To verify testing, our app checks for specific package installations on your device. We ONLY scan for the package names of apps you have assigned to test.
*   **Karma Logs**: We store records of your credit earnings and expenditures to ensure a fair ecosystem.

## 2. How We Use Your Data
*   **Verification**: To confirm app installation so you can earn Karma rewards.
*   **Security**: To prevent abuse (e.g., testing your own apps) and ensure 100% genuine testers.

## 3. Data Sharing
*   **With Developers**: Developers see that a verified user has installed their app. We do NOT share your private email or phone number.
*   **No Third-Party Sales**: We never sell your data to advertisers or third parties.

## 4. Your Rights
You can request account deletion at any time via the community forum or support channel.

---
*By using Sajuriya Tester, you agree to these terms.*
""";

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SafeArea(
        child: Markdown(
        data: privacyContent,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          h1: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          h2: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          p: GoogleFonts.inter(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          listBullet: GoogleFonts.inter(
            fontSize: 14,
            color: colorScheme.primary,
          ),
        ),
        ), // Markdown
      ), // SafeArea
    ); // Scaffold
  }
}
