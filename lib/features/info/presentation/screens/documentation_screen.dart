import 'package:flutter/material.dart';
import 'package:sajuriyatester/core/widgets/skeleton_widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentationScreen extends StatelessWidget {
  const DocumentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String groupEmail = "sajuriya-tester@googlegroups.com";
    
    final String markdownContent = """
# Getting Started with Sajuriya Tester

Sajuriya Tester is a community built to help developers conquer the Google Play **20-tester requirement**. Follow this guide to start earning Karma and testing your own apps.

---

## 🛡️ Step 1: Join the Community (Testers)
Before you can install any app from the marketplace, you **must** be a member of our official testing group.

### Join the Google Group
Join our [Google Group](https://groups.google.com/g/sajuriya-tester) using the button above. 
*   **Mandatory**: You must join using the email address you use for the Play Store.
*   **Reward**: Membership allows you to test apps and earn **Karma Credits**.

![Join Group Step](https://via.placeholder.com/600x300/6366f1/ffffff?text=Step+1:+Join+Google+Group)

---

## 🚀 Step 2: Listing Your Own App (Developers)
To get 20 testers for your app, you must configure your Google Play Console correctly.

### 1. Enable Closed Testing
In your Google Play Console, go to **Testing > Closed testing**. Create a new track or use any existing one.

### 2. Add Our Google Group
In the **Testers** tab of your track:
1.  Select **Google Groups** as the tester type.
2.  Click **Add Groups**.
3.  Enter: `$groupEmail`
4.  Save the changes.

### 3. Select Countries
Go to the **Countries/regions** tab and select **Add countries/regions**. We recommend selecting **All countries/regions** to ensure maximum tester availability.

### 4. Send for Review
Submit your track for review. Once Google approves your testing track, you can list your app on **Sajuriya Tester**.

![Play Console Setup](https://via.placeholder.com/600x300/10b981/ffffff?text=Step+2:+Play+Console+Configuration)

---

## 💎 Step 3: Earning & Spending Karma
*   **Earn**: Install an app, open it daily, and keep it installed for 14 days.
*   **Spend**: Use your Karma to "Purchase" tester slots for your app listing.
*   **Verification**: Our system automatically verifies your testing status. Do not uninstall apps manually if you want to keep your credits!

---

## 🛠️ Troubleshooting: "Item Not Found" Error
This is the most common issue in Google Play closed testing. If you see "Item not found" or "URL was not found on this server" in the Play Store:

1.  **Check Group Membership**: Did you join our [Google Group](https://groups.google.com/g/sajuriya-tester)? Membership is required for Google to reveal the app.
2.  **The Opt-In Step**: After clicking "Download" in our app, you will be taken to a Google Web page. You **MUST** click the **"Become a Tester"** button there before the Play Store link will work.
3.  **Active Account Check**: If you have multiple Google accounts, ensure the Play Store is currently using the *identical* email you used to join the group.
4.  **Sync Delay**: Google's servers can take **30-60 minutes** to propagate group membership. If you just joined, please wait a while.
5.  **Clear Play Store Cache**: If the error persists, go to **Settings > Apps > Google Play Store > Storage** and click **"Clear Cache"**, then restart the Play Store app.

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
            child: Row(
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
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Markdown(
              data: markdownContent,
              selectable: true,
              sizedImageBuilder: (config) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
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
                          Text('Step Image Placeholder', style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
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
