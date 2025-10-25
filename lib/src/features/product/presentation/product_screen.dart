import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/fooddb_repository.dart';
import '../../../data/models/product.dart';
import '../../../routing/app_router.dart';
import '../../../data/off/off_auth.dart';
import '../../../data/prefs/prefs_repository.dart';
import 'add_photo_sheet.dart';
import 'edit_product_sheet.dart';
import 'robotoff_questions_sheet.dart';

class ProductScreen extends StatefulWidget {
  final String barcode;
  const ProductScreen({super.key, required this.barcode});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Future<Product?> _future;
  Product? _latestProduct;
  int _fetchVersion = 0;

  @override
  void initState() {
    super.initState();
    final Future<Product?> initial = _createFetchFuture();
    _future = initial;
    final int token = ++_fetchVersion;
    initial.then((Product? value) {
      if (!mounted || token != _fetchVersion) return;
      setState(() => _latestProduct = value);
    });
  }

  Future<Product?> _createFetchFuture() {
    final FoodDbRepository repo = context.read<FoodDbRepository>();
    final prefs = context.read<PrefsController>().prefs;
    return repo.fetchByBarcode(
      widget.barcode,
      languageCode: prefs.language,
      countryCode: prefs.country,
    );
  }

  Future<void> _refresh() async {
    final Future<Product?> next = _createFetchFuture();
    final int token = ++_fetchVersion;
    setState(() => _future = next);
    final Product? result = await next;
    if (!mounted || token != _fetchVersion) return;
    setState(() => _latestProduct = result);
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<OffAuth>().isLoggedIn;
    final prefs = context.watch<PrefsController>().prefs;
    final String languageTag =
        (prefs.language ?? '').trim().toLowerCase();
    final String countryTag = (prefs.country ?? '').trim().toLowerCase();
    final String filtersCaption = [
      if (languageTag.isNotEmpty) 'lc=$languageTag',
      if (countryTag.isNotEmpty) 'cc=$countryTag',
    ].join(', ');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          // Lists feature removed in Step 20 (previous Add-to-list action deleted)
          if (loggedIn)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final product = _latestProduct;
                if (product == null) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Load the product first')),
                  );
                  return;
                }
                final ok = await showModalBottomSheet<bool>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (_) => EditProductSheet(product: product),
                );
                if (!mounted) return;
                if (ok == true) _refresh();
              },
            ),
        ],
      ),
      floatingActionButton: loggedIn
          ? FloatingActionButton.extended(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await showModalBottomSheet<bool>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (_) => AddPhotoSheet(barcode: widget.barcode),
                );
                if (!mounted) return;
                if (ok == true) {
                  messenger.showSnackBar(
                    const SnackBar(
                        content:
                            Text('Photo uploaded. Pull to refresh images.')),
                  );
                }
              },
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add photo'),
            )
          : null,
      body: FutureBuilder<Product?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = snap.data;
          if (product == null) return _NotFound(barcode: widget.barcode);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (filtersCaption.isNotEmpty) ...[
                  Text(
                    filtersCaption,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                _HeroImage(url: product.imageUrl),
                const SizedBox(height: 16),
                _Overview(product: product),
                const SizedBox(height: 16),
                _Nutrition(product: product),
                if ((product.ingredientsText?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(height: 16),
                  _Ingredients(text: product.ingredientsText!),
                ],
                if ((product.allergens?.isNotEmpty ?? false) ||
                    (product.additives?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 16),
                  _AllergensAdditives(
                    allergens: product.allergens ?? const [],
                    additives: product.additives ?? const [],
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder: (_) =>
                        RobotoffQuestionsSheet(barcode: product.barcode),
                  ),
                  icon: const Icon(Icons.question_mark),
                  label: const Text('Questions'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.scan),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan another'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Clipboard.setData(
                            ClipboardData(text: product.barcode)),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy barcode'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? url;
  const _HeroImage({required this.url});
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: (url == null)
              ? const Center(child: Icon(Icons.image_not_supported, size: 48))
              : Image.network(url!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final Product product;
  const _Overview({required this.product});
  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (product.nutritionGrade != null && product.nutritionGrade!.isNotEmpty) {
      final grade = product.nutritionGrade!.toUpperCase();
      chips.add(Chip(label: Text('Nutri-Score $grade')));
    }
    if (product.quantity != null && product.quantity!.isNotEmpty) {
      chips.add(Chip(label: Text(product.quantity!)));
    }
    if ((product.labels?.isNotEmpty ?? false)) {
      chips.addAll(product.labels!.take(3).map((l) => Chip(label: Text(l))));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.name ?? 'Unnamed product',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Brand: ${product.brand ?? '—'}'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
        const SizedBox(height: 8),
        SelectableText('Barcode: ${product.barcode}'),
      ],
    );
  }
}

class _Nutrition extends StatelessWidget {
  final Product product;
  const _Nutrition({required this.product});

  Widget _kv(BuildContext ctx, String label, double? v, {String unit = 'g'}) {
    final text = (v == null)
        ? '—'
        : (v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1) + unit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(ctx).textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(text, style: Theme.of(ctx).textTheme.bodyLarge),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nutrition (per 100g/ml)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _kv(context, 'Energy', product.energyKcal100g, unit: ' kcal'),
                _kv(context, 'Fat', product.fat100g),
                _kv(context, 'Sat. fat', product.saturatedFat100g),
                _kv(context, 'Carbs', product.carbs100g),
                _kv(context, 'Sugars', product.sugars100g),
                _kv(context, 'Fiber', product.fiber100g),
                _kv(context, 'Protein', product.proteins100g),
                _kv(context, 'Salt', product.salt100g),
                _kv(context, 'Sodium', product.sodium100g),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Ingredients extends StatelessWidget {
  final String text;
  const _Ingredients({required this.text});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class _AllergensAdditives extends StatelessWidget {
  final List<String> allergens;
  final List<String> additives;
  const _AllergensAdditives({required this.allergens, required this.additives});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Allergens & additives',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (allergens.isEmpty)
              const Text('Allergens: —')
            else
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      allergens.map((a) => Chip(label: Text(a))).toList()),
            const SizedBox(height: 8),
            if (additives.isEmpty)
              const Text('Additives: —')
            else
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: additives
                      .map((a) => Chip(label: Text(a.toUpperCase())))
                      .toList()),
          ],
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  final String barcode;
  const _NotFound({required this.barcode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 56),
            const SizedBox(height: 12),
            Text('No product found for $barcode', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.scan),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan another'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: barcode)),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy code'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
