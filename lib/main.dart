import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sajuriyatester/core/theme/app_theme.dart';
import 'package:sajuriyatester/core/theme/theme_provider.dart';
import 'package:sajuriyatester/features/auth/presentation/screens/splash_screen.dart';
import 'package:sajuriyatester/features/auth/presentation/screens/auth_screen.dart';
import 'package:sajuriyatester/features/auth/presentation/providers/auth_provider.dart';
import 'package:sajuriyatester/core/models/app_model.dart';

import 'package:sajuriyatester/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:sajuriyatester/features/marketplace/presentation/screens/my_apps_screen.dart';
import 'package:sajuriyatester/features/marketplace/presentation/screens/add_app_screen.dart';
import 'package:sajuriyatester/features/marketplace/presentation/screens/edit_app_screen.dart';
import 'package:sajuriyatester/features/marketplace/presentation/screens/app_details_screen.dart';
import 'package:sajuriyatester/features/marketplace/presentation/screens/report_app_screen.dart';
import 'package:sajuriyatester/features/tests/presentation/screens/my_tests_screen.dart';
import 'package:sajuriyatester/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:sajuriyatester/features/profile/presentation/screens/profile_screen.dart';
import 'package:sajuriyatester/features/navigation/presentation/main_navigation_screen.dart';
import 'package:sajuriyatester/features/admin/presentation/screens/admin_dashboard.dart';
import 'package:sajuriyatester/features/admin/presentation/screens/app_moderation_screen.dart';
import 'package:sajuriyatester/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:sajuriyatester/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:sajuriyatester/features/info/presentation/screens/documentation_screen.dart';
import 'package:sajuriyatester/features/info/presentation/screens/privacy_policy_screen.dart';
import 'package:sajuriyatester/features/info/presentation/screens/about_screen.dart';
import 'package:sajuriyatester/features/info/presentation/screens/help_support_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sajuriyatester/core/services/local_cache_service.dart';
import 'package:sajuriyatester/core/providers/common_providers.dart';

void main() async {
  // 1. Initialize binding early
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Run a simple loading app immediately to replace the native splash screen
  runApp(_BootSplash());

  try {
    debugPrint('Loading environment variables...');
    await dotenv.load(fileName: ".env");
    
    debugPrint('Initializing Supabase...');
    final url = dotenv.get('SUPABASE_URL');
    final anonKey = dotenv.get('SUPABASE_ANON_KEY');
    
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    // Initialize Local Cache (Hive)
    debugPrint('Initializing Local Cache...');
    final cacheService = LocalCacheService();
    await cacheService.init();
    
    debugPrint('Initialization complete. Launching main app...');
    // 3. Replace the loading app with the real app and its state
    runApp(ProviderScope(
      overrides: [
        localCacheServiceProvider.overrideWithValue(cacheService),
      ],
      child: const MyApp(),
    ));
  } catch (e, stack) {
    debugPrint('FATAL ERROR DURING INITIALIZATION: $e');
    debugPrint(stack.toString());
    
    runApp(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text('Initialization Failed', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}



/// Branded shimmer splash shown during async initialisation.
class _BootSplash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF09090B), // Matching AppTheme.backgroundColor
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo mark
              Shimmer.fromColors(
                baseColor: const Color(0xFF6A3DE8), // Matching AppTheme.primaryColor
                highlightColor: const Color(0xFF8B5CF6),
                period: const Duration(milliseconds: 1200),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A3DE8),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // App name shimmer
              Shimmer.fromColors(
                baseColor: Colors.white70,
                highlightColor: Colors.white,
                period: const Duration(milliseconds: 1400),
                child: const Text(
                  'Sajuriya Tester',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Initializing platform...',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.read(authServiceProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    redirect: (context, state) {
      final user = authService.currentUser;
      final isAuth = user != null;

      final isSplash = state.matchedLocation == '/splash';
      final isAuthScreen = state.matchedLocation == '/auth';
      final isLoggingIn = isSplash || isAuthScreen;

      // 1. If not authenticated and trying to access a protected route → go to /auth
      if (!isAuth && !isLoggingIn) {
        return '/auth';
      }

      // 2. If authenticated and on an entry screen → go to /marketplace
      if (isAuth && isLoggingIn) {
        return '/marketplace';
      }

      // 3. Handle bare root path
      if (state.matchedLocation == '/') {
        return isAuth ? '/marketplace' : '/splash';
      }

      // 4. Guard all /admin routes — only 'admin' role users may enter
      final isAdminRoute = state.matchedLocation.startsWith('/admin');
      if (isAdminRoute && isAuth) {
        final isAdmin = ref.read(currentUserIsAdminProvider);
        if (!isAdmin) {
          return '/marketplace'; // Silently redirect non-admins
        }
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Navigation Error: ${state.error}', style: const TextStyle(fontSize: 16)),
            TextButton(
              onPressed: () => context.go('/marketplace'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/my-apps',
        builder: (context, state) => const MyAppsScreen(),
      ),
      GoRoute(
        path: '/add-app',
        builder: (context, state) => const AddAppScreen(),
      ),
      GoRoute(
        path: '/edit-app',
        builder: (context, state) {
          final app = state.extra as AppModel?;
          if (app == null) return const MyAppsScreen();
          return EditAppScreen(app: app);
        },
      ),
      GoRoute(
        path: '/app-details',
        builder: (context, state) {
          final app = state.extra as AppModel?;
          if (app == null) return const MarketplaceScreen();
          return AppDetailsScreen(app: app);
        },
      ),
      GoRoute(
        path: '/report-app',
        builder: (context, state) {
          final app = state.extra as AppModel?;
          if (app == null) return const MarketplaceScreen();
          return ReportAppScreen(app: app);
        },
      ),
      GoRoute(
        path: '/documentation',
        name: 'documentation',
        builder: (context, state) => const DocumentationScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/help-support',
        name: 'help-support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
        routes: [
          GoRoute(
            path: 'apps',
            builder: (context, state) => const AppManagementScreen(),
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) => const AdminReportsScreen(),
          ),
        ],
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/marketplace',
            builder: (context, state) => const MarketplaceScreen(),
          ),
          GoRoute(
            path: '/my-tests',
            builder: (context, state) => const MyTestsScreen(),
          ),
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Sajuriya Tester',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
