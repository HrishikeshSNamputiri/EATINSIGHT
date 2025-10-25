import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/scan/presentation/scan_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/prices/presentation/prices_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/preferences_screen.dart';
import '../features/product/presentation/product_screen.dart';
import 'scaffold_with_nav.dart';

class AppRoutes {
  static const home = '/';
  static const prefs = '/prefs';
  static const scan = '/scan';
  static const search = '/search';
  static const prices = '/prices';
  static const profile = '/profile';
  static const product = '/product/:barcode';
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: <RouteBase>[
          GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.scan, builder: (_, __) => const ScanScreen()),
          GoRoute(path: AppRoutes.search, builder: (_, __) => const SearchScreen()),
          GoRoute(path: AppRoutes.prices, builder: (_, __) => const PricesScreen()),
          GoRoute(path: AppRoutes.prefs, builder: (_, __) => const PreferencesScreen()),
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: AppRoutes.product,
            builder: (context, state) {
              final code = state.pathParameters['barcode'] ?? '';
              return ProductScreen(barcode: code);
            },
          ),
        ],
      ),
    ],
  );
}
