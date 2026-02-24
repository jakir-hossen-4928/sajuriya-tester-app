import 'package:flutter/services.dart';

/// A lightweight utility to check if a specific app is installed on the device
/// WITHOUT requiring the QUERY_ALL_PACKAGES permission.
///
/// This works by using Android's PackageManager.getPackageInfo() for a specific
/// package name, which only requires declaring the package in AndroidManifest.xml
/// using `queries` tags (or the app can query its own package).
///
/// For checking arbitrary packages at runtime, we use a MethodChannel approach
/// that catches NameNotFoundException instead of querying all packages.
class AppChecker {
  static const _channel = MethodChannel('com.sajuriyaStudio.sajuriyatester/app_checker');

  /// Returns true if the app with [packageName] is installed on the device.
  static Future<bool> isAppInstalled(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isAppInstalled',
        {'packageName': packageName},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
