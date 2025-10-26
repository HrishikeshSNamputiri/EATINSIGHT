import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../routing/app_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = <_Nav>[
      _Nav('Scan', AppRoutes.scan, Icons.qr_code_scanner),
      _Nav('Search', AppRoutes.search, Icons.search),
      _Nav('Profile', AppRoutes.profile, Icons.person),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('EATINSIGHT')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: cards.map((c) {
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  if (context.mounted) context.go(c.route);
                },
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.icon, size: 40),
                      const SizedBox(height: 8),
                      Text(c.label, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Nav {
  final String label;
  final String route;
  final IconData icon;
  const _Nav(this.label, this.route, this.icon);
}
