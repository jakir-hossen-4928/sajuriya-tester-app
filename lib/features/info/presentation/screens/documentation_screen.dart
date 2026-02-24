import 'package:flutter/material.dart';
import 'package:sajuriyatester/core/widgets/skeleton_widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentationScreen extends StatelessWidget {
  const DocumentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String groupEmail = "sajuriya-tester@googlegroups.com";
    
    final String markdownContent = """
# Sajuriya Tester – Testing Instructions

Sajuriya Tester is a community built to help developers conquer the Google Play **12-tester requirement**. Follow this guide to start earning Karma and testing your own apps.

---

## 🛡️ 1. Join the Sajuriya Tester Google Group (Required)

Before testing any developer’s app, you **must** first join our Google Group. This is mandatory for closed testing on Google Play.

### [sajuriya-tester@googlegroups.com](https://groups.google.com/g/sajuriya-tester)

*   **Mandatory**: Joining this group is required for closed testing to work.
*   **Visibility**: After joining, apps shared by developers will become visible to you on the Play Store.
*   **Mutual Growth**: You will be able to test other developers’ apps, and they can test yours.
*   **Avoid Errors**: If you do not join, the Play Store will show **"Item Not Found"**.

![Join Group](asset:asstes/icons/group-join-screenshot.png)

---

## 🚀 2. Steps for Developers (Closed Testing Setup)

If you are a developer and want to get testers for your app, follow these steps in the **Google Play Console**:

### 1. Configure Testers
Go to your app → **Testing > Closed testing**. Create a track and select **Google Groups** as the tester type.

### 2. Add Our Group
Click **Add Groups** and enter: `$groupEmail`

![Add Group](asset:asstes/icons/closed-tester-google-group-add-screenshort.png)

### 3. Select Countries
Go to the **Countries/regions** tab and select **Add countries/regions**. We recommend selecting **All Countries** to ensure maximum tester availability.

![Select Countries](asset:asstes/icons/select-all-country-in-closed-testing-screenshort.png)

### 4. Submit for Review
Go to the **Review and release** tab and click **Send for review**. Once approved, community members will be able to access your app.

![Submit Review](asset:asstes/icons/send-the-changes-for-review-screenshort.png)

---

## 🛠️ 3. Fix "Item Not Found" Issue

If you see the **"Item Not Found"** error even after joining the group:

*   **Check Email**: Ensure you joined the Google Group using the **exact same email** as your Google Play Store account.
*   **Switch Accounts**: If you have multiple emails, switch the Play Store primary account to the one that joined the group.
*   **Sync Time**: Google can take 30-60 minutes to sync your group membership.

![Troubleshooting](asset:asstes/icons/item-not-found.jpg)

---
""";

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentation'),
      ),
      body: SafeArea(
        child: Column(
        children: [
          // Copy Email Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('REQUIRED GOOGLE GROUP EMAIL', 
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold, 
                              color: colorScheme.primary, 
                              letterSpacing: 1,
                            )),
                          const SizedBox(height: 4),
                          Text(groupEmail, style: TextStyle(
                            fontWeight: FontWeight.w600, 
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          )),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: groupEmail));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                        foregroundColor: colorScheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse('https://groups.google.com/g/sajuriya-tester');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.group_add_rounded, size: 18),
                    label: const Text('Join Our Google Group Community'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Markdown(
              data: markdownContent,
              selectable: true,
              onTapLink: (text, href, title) async {
                if (href != null) {
                  final url = Uri.parse(href);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                }
              },
              sizedImageBuilder: (config) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: config.uri.toString().startsWith('asset:')
                      ? Image.asset(
                          config.uri.toString().replaceFirst('asset:', ''),
                          width: config.width,
                          height: config.height,
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          config.uri.toString(),
                          width: config.width,
                          height: config.height,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported_outlined, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), size: 40),
                                const SizedBox(height: 8),
                                Text('Image Placeholder', style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const ImageSkeleton(
                              size: 200,
                              borderRadius: 12,
                            );
                          },
                        ),
                ),
              ),
              styleSheet: MarkdownStyleSheet(
                h1: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                h2: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary),
                h3: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                p: GoogleFonts.inter(fontSize: 15, color: colorScheme.onSurfaceVariant, height: 1.6),
                listBullet: GoogleFonts.inter(fontSize: 15, color: colorScheme.primary),
                code: TextStyle(backgroundColor: colorScheme.surfaceContainerHighest, color: colorScheme.onSurface),
                horizontalRuleDecoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
