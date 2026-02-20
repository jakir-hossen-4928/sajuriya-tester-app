package com.sajuriyaStudio.sajuriyatester

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sajuriyaStudio.sajuriyatester/app_checker"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isAppInstalled") {
                val packageName = call.argument<String>("packageName")
                if (packageName == null) {
                    result.error("INVALID_ARGUMENT", "packageName is required", null)
                    return@setMethodCallHandler
                }
                try {
                    // This does NOT require QUERY_ALL_PACKAGES.
                    // On Android 11+, it requires the package to be declared
                    // in <queries> in AndroidManifest.xml, OR the calling app
                    // can always see itself.
                    packageManager.getPackageInfo(packageName, 0)
                    result.success(true)
                } catch (e: PackageManager.NameNotFoundException) {
                    result.success(false)
                } catch (e: Exception) {
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
