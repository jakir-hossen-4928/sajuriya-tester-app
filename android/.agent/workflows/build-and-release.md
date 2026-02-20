---
description: How to build and release the Sajuriya Tester Android app to the Google Play Store
---

# 🚀 Build & Release Android App — Sajuriya Tester

This workflow walks you through every step to prepare and publish **Sajuriya Tester** to the Google Play Store.

---

## ✅ Pre-Flight Checklist (Already Done)

The following items have already been configured in your project:

- [x] **Launcher Icon** — Custom icon generated across all mipmap densities (`launcher_icon`)
- [x] **Material Components** — `styles.xml` updated for both light and dark themes
- [x] **Material Dependency** — `com.google.android.material:material:1.12.0` added to `build.gradle.kts`
- [x] **INTERNET Permission** — Added to `AndroidManifest.xml`
- [x] **App Manifest** — Label set to "Sajuriya Tester", icon set to `@mipmap/launcher_icon`
- [x] **Gradle Signing Config** — `build.gradle.kts` configured to load `key.properties` for release signing
- [x] **`.gitignore`** — `key.properties`, `*.jks`, and `*.keystore` are excluded from version control

---

## 📝 Step-by-Step Release Process

### Step 1: Generate an Upload Keystore

If you **don't already have** an upload keystore, generate one.

First, find the path to `keytool` by running:

```powershell
flutter doctor -v
```
Look for the `Java binary at:` line. Replace `java` with `keytool` in that path.

Then run this command in PowerShell:

```powershell
keytool -genkey -v -keystore $env:USERPROFILE\upload-keystore.jks `
        -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 `
        -alias upload
```

You'll be prompted for:
- **Keystore password** — Choose a strong password (remember it!)
- **Key password** — Can be the same as the keystore password
- **Your name, organization, city, state, country** — Fill in your info

> ⚠️ **IMPORTANT:** Keep the keystore file (`upload-keystore.jks`) safe and private! If you lose it, you cannot update your app on the Play Store.

---

### Step 2: Update `key.properties`

Edit `android/key.properties` with your actual values:

```properties
storePassword=YOUR_ACTUAL_KEYSTORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD
keyAlias=upload
storeFile=C:\\Users\\YOUR_USERNAME\\upload-keystore.jks
```

> 🔒 **Note:** The `key.properties` file is already in `.gitignore` — it will NOT be committed to source control.

> ⚠️ **Windows paths must use double backslashes** (`\\`).

---

### Step 3: Update the App Version (Name Only)

Edit `pubspec.yaml` and update the version number:

```yaml
version: 1.0.1+1
```

- **`versionName` (1.0.1)**: Change this to reflect your release version.
- **`versionCode` (+1)**: You can leave this as `+1` in `pubspec.yaml`. The actual `versionCode` is now **automatically generated** at build time using a timestamp in `android/app/build.gradle.kts`. This ensures you never face "version code collision" errors.

---

### Step 4: Clean the Project

```powershell
flutter clean
flutter pub get
```

---

### Step 5: Build the App Bundle (Recommended)

Google Play Store prefers `.aab` (App Bundle) format:

```powershell
flutter build appbundle
```

The output will be at:
```
build/app/outputs/bundle/release/app-release.aab
```

#### Optional: Build with obfuscation (recommended for production)

```powershell
flutter build appbundle --obfuscate --split-debug-info=build/debug-info
```

> 💡 Keep the `build/debug-info` folder — you'll need it to de-obfuscate crash stack traces.

---

### Step 5b (Alternative): Build APK

If you need APKs instead of an app bundle:

```powershell
# Split APKs (smaller downloads per device architecture)
flutter build apk --split-per-abi

# OR a single fat APK (larger but universal)
flutter build apk
```

Split APK outputs:
```
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

---

### Step 6: Test the Release Build

Before uploading to Play Store, test on a real device:

```powershell
flutter install
```

Or manually install the APK:
```powershell
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Verify:
- [ ] App launches without crashing
- [ ] Google Sign-In works
- [ ] Supabase connection works
- [ ] All major features function correctly
- [ ] App icon appears correctly in the launcher
- [ ] Deep links work (`sajuriyatester://login-callback`)

---

### Step 7: Publish to Google Play Store

1. Go to [Google Play Console](https://play.google.com/console)
2. Create a new app (or select existing "Sajuriya Tester")
3. Fill in the **Store Listing**:
   - App name: **Sajuriya Tester**
   - Short description
   - Full description
   - Screenshots (phone, tablet, etc.)
   - Feature graphic (1024x500)
   - App category
   - Contact details
4. Complete the **Content Rating** questionnaire
5. Complete the **Data Safety** form (see previous conversation for your `data_safety.csv`)
6. Set up **Pricing & Distribution**
7. Navigate to **Release** → **Production** (or **Internal Testing** first)
8. Upload `app-release.aab`
9. Review and roll out

---

## 🔧 Quick Reference

### Project Configuration Summary

| Property | Value |
|----------|-------|
| **App Name** | Sajuriya Tester |
| **Application ID** | `com.sajuriyaStudio.sajuriyatester` |
| **Version** | `1.0.0+1` |
| **Min SDK** | Flutter default |
| **Target SDK** | Flutter default |
| **Signing** | Upload key via `key.properties` |
| **Icon** | `@mipmap/launcher_icon` |

### Important Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` | App version, dependencies |
| `android/key.properties` | Keystore credentials (🔒 private) |
| `android/app/build.gradle.kts` | Build config, signing config |
| `android/app/src/main/AndroidManifest.xml` | App manifest, permissions |
| `android/app/src/main/res/values/styles.xml` | Light theme |
| `android/app/src/main/res/values-night/styles.xml` | Dark theme |

### Common Commands

```powershell
# Clean rebuild
flutter clean && flutter pub get

# Build release app bundle
flutter build appbundle

# Build release app bundle with obfuscation
flutter build appbundle --obfuscate --split-debug-info=build/debug-info

# Build release APK (split by architecture)
flutter build apk --split-per-abi

# Install on connected device
flutter install

# Check everything is configured correctly
flutter doctor -v
```

---

## ❓ FAQ

### Q: Can I change the Application ID after publishing?
**No.** Once published, the `applicationId` (`com.sajuriyaStudio.sajuriyatester`) cannot be changed. It's the unique identifier on the Play Store.

### Q: What if I lose my upload keystore?
Contact Google Play support. You can use [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756) to recover. **Strongly recommended:** Enable Play App Signing and back up your keystore securely.

### Q: App bundle vs APK?
**Always prefer App Bundle (`.aab`)**. Google Play optimizes delivery per device, resulting in smaller downloads. APKs are only needed for distribution outside the Play Store.

### Q: How do I update the app later?
1. Increment the version in `pubspec.yaml` (e.g., `1.0.1+2`)
2. Run `flutter build appbundle`
3. Upload the new `.aab` to Google Play Console
4. Roll out the update
