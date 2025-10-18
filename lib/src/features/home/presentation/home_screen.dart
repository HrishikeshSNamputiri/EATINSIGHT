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
      _Nav('Prices', AppRoutes.prices, Icons.currency_rupee),
      _Nav('Lists', AppRoutes.lists, Icons.list),
      _Nav('Profile', AppRoutes.profile, Icons.person),
      // Dev helper tile (easy to remove later)
      _Nav('(Dev) Open by barcode', '/__dev_open__', Icons.play_arrow),
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
                  if (c.route == '/__dev_open__') {
                    final code = await _promptBarcode(context);
                    if (code != null && code.trim().isNotEmpty) {
                      // Navigate directly to the product page
                      // ignore: use_build_context_synchronously
                      context.go('/product/${code.trim()}');
                    }
                    return;
                  }
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

Future<String?> _promptBarcode(BuildContext context) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Open by barcode'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Enter barcode',
            hintText: 'e.g., 5449000000996',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(ctrl.text), child: const Text('Open')),
        ],
      );
    },
  );
}
