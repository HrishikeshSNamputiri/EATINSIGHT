import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:provider/provider.dart';

import '../../../../data/fx/fx_api.dart';
import '../../../../data/prefs/prefs_repository.dart';
import '../../../../data/prices/open_prices_api.dart';
import '../../../../data/models/product.dart';

/// Renders price information inline on the product page.
class ProductPricesTile extends StatefulWidget {
  const ProductPricesTile({super.key, required this.product});

  final Product product;

  @override
  State<ProductPricesTile> createState() => _ProductPricesTileState();
}

class _ProductPricesTileState extends State<ProductPricesTile> {
  late final Future<List<_DisplayLine>> _future = _load();

  Future<List<_DisplayLine>> _load() async {
    final prefs = context.read<PrefsController>().prefs;
    final String? cc = prefs.country?.trim();
    final String userCurrency = (prefs.currency ?? '').trim().toUpperCase();

    final List<off.Price> fetched = await OpenPricesApi.getPricesForBarcode(
      barcode: widget.product.barcode,
      countryCode: cc,
    );
    if (fetched.isEmpty) return const <_DisplayLine>[];

    final List<off.Price> source = OpenPricesApi.latestPerCountry(fetched);

    final fx = FxApi();
    final List<_DisplayLine> lines = [];

    for (final price in source) {
      final off.Currency currency = price.currency;
      final num rawAmount = price.price;
      final String nativeCurrency = currency.name;
      final double amount = rawAmount.toDouble();

      double? converted;
      if (userCurrency.isNotEmpty && userCurrency != nativeCurrency) {
        converted = await fx.convert(amount: amount, from: nativeCurrency, to: userCurrency);
      }

      lines.add(_DisplayLine(
        countryCode: price.location?.countryCode?.toUpperCase() ?? '',
        nativeAmount: amount,
        nativeCurrency: nativeCurrency,
        convertedAmount: converted,
        convertedCurrency: converted != null ? userCurrency : null,
      ));

      if (lines.length >= 8) break;
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_DisplayLine>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            title: Text('Prices'),
            subtitle: Text('Loading…'),
          );
        }
        if (snapshot.hasError) {
          return const ListTile(
            title: Text('Prices'),
            subtitle: Text('Could not load prices.'),
          );
        }
        final lines = snapshot.data ?? const <_DisplayLine>[];
        if (lines.isEmpty) {
          return const ListTile(
            title: Text('Prices'),
            subtitle: Text('No prices listed.'),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prices', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...lines.map((line) => _PriceRow(line: line)),
            ],
          ),
        );
      },
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.line});

  final _DisplayLine line;

  @override
  Widget build(BuildContext context) {
    final String native =
        '${_format(line.nativeAmount)} ${line.nativeCurrency}';
    final String converted = (line.convertedCurrency != null && line.convertedAmount != null)
        ? ' (${_format(line.convertedAmount!)} ${line.convertedCurrency})'
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (line.countryCode.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                line.countryCode,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          if (line.countryCode.isNotEmpty) const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$native$converted',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _format(double value) {
    if (value >= 100) return value.toStringAsFixed(0);
    if (value >= 10) return value.toStringAsFixed(1);
    if (value >= 1) return value.toStringAsFixed(2);
    return value.toStringAsFixed(3);
  }
}

class _DisplayLine {
  const _DisplayLine({
    required this.countryCode,
    required this.nativeAmount,
    required this.nativeCurrency,
    required this.convertedAmount,
    required this.convertedCurrency,
  });

  final String countryCode;
  final double nativeAmount;
  final String nativeCurrency;
  final double? convertedAmount;
  final String? convertedCurrency;
}
