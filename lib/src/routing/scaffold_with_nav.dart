import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import '../data/prefs/prefs_repository.dart';
import '../widgets/currency_symbol_icon.dart';

class ScaffoldWithNavBar extends StatefulWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  static const List<String> _routes = <String>[
    AppRoutes.home,
    AppRoutes.scan,
    AppRoutes.search,
    AppRoutes.prices,
    AppRoutes.profile,
  ];

  int _index = 0;

  int _locationToIndex(String location) {
    final int match = _routes.indexWhere(
      (String route) => location == route || location.startsWith('$route/'),
    );
    return match >= 0 ? match : 0;
  }

  void _onTap(int value) {
    debugPrint('[ScaffoldWithNavBar] onTap -> value=$value (oldIndex=$_index)');
    setState(() => _index = value);
    context.go(_routes[value]);
  }

  Widget _buildPricesIcon(String currency, {double size = 24}) {
    final String normalized = currency.trim().toUpperCase();
    debugPrint('[ScaffoldWithNavBar] _buildPricesIcon normalized="$normalized" size=$size');
    if (normalized.isEmpty) {
      return Icon(Icons.currency_rupee, size: size);
    }
    return CurrencySymbolIcon(code: normalized, size: size);
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    _index = _locationToIndex(location);
    // Read prefs inside the drawer so currency icon stays in sync.
    final prefs = context.watch<PrefsController>().prefs;
    final String currency = prefs.currency ?? '';
    debugPrint(
      '[ScaffoldWithNavBar] build -> location=$location, index=$_index, currency="$currency", prefsHash=${prefs.hashCode}',
    );

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTap,
        destinations: <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code),
            label: 'Scan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: _buildPricesIcon(currency),
            selectedIcon: _buildPricesIcon(currency, size: 26),
            label: 'Prices',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      drawer: _AppDrawer(currentIndex: _index, onSelect: _onTap),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const _AppDrawer({required this.currentIndex, required this.onSelect});

  void _handleTap(BuildContext context, int index) {
    Navigator.of(context).pop();
    onSelect(index);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PrefsController>().prefs;
    final String code = (prefs.currency ?? '').trim().toUpperCase();
    debugPrint(
      '[AppDrawer] build -> currentIndex=$currentIndex, selectedCurrency="$code", prefsHash=${prefs.hashCode}',
    );
    final Widget pricesIcon =
        code.isEmpty ? const Icon(Icons.currency_rupee) : CurrencySymbolIcon(code: code, size: 22);
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(child: Text('EATINSIGHT')),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: currentIndex == 0,
              onTap: () => _handleTap(context, 0),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Scan'),
              selected: currentIndex == 1,
              onTap: () => _handleTap(context, 1),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search'),
              selected: currentIndex == 2,
              onTap: () => _handleTap(context, 2),
            ),
            // Dynamic Prices icon based on current currency
            ListTile(
              leading: pricesIcon,
              title: const Text('Prices'),
              selected: currentIndex == 3,
              onTap: () => _handleTap(context, 3),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              selected: currentIndex == 4,
              onTap: () => _handleTap(context, 4),
            ),
          ],
        ),
      ),
    );
  }
}
