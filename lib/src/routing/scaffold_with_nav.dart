import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  static final _destinations = <_Dest>[
    _Dest('Home', AppRoutes.home, Icons.home_outlined),
    _Dest('Scan', AppRoutes.scan, Icons.qr_code_scanner),
    _Dest('Search', AppRoutes.search, Icons.search),
    _Dest('Prices', AppRoutes.prices, Icons.currency_rupee),
    _Dest('Profile', AppRoutes.profile, Icons.person),
  ];

  int _indexFromLocation(String loc) {
    final i = _destinations.indexWhere((d) => loc == d.route || loc.startsWith('${d.route}/'));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexFromLocation(loc);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          final dest = _destinations[i];
          if (dest.route != loc) context.go(dest.route);
        },
        destinations: _destinations
            .map((d) => NavigationDestination(icon: Icon(d.icon), label: d.label))
            .toList(),
      ),
    );
  }
}

class _Dest {
  final String label;
  final String route;
  final IconData icon;
  const _Dest(this.label, this.route, this.icon);
}
