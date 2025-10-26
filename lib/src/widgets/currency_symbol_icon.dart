import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Renders an icon that reflects the selected currency.
/// Falls back to a textual currency symbol when a dedicated Material icon
/// is not available for the given ISO code.
class CurrencySymbolIcon extends StatelessWidget {
  final String? code;
  final double size;
  const CurrencySymbolIcon({super.key, this.code, this.size = 24});

  IconData? _iconFor(String normalizedCode) {
    switch (normalizedCode) {
      case 'INR':
        return Icons.currency_rupee;
      case 'USD':
      case 'AUD':
      case 'CAD':
      case 'NZD':
      case 'SGD':
      case 'MXN':
      case 'ARS':
      case 'CLP':
      case 'COP':
        return Icons.attach_money; // $
      case 'EUR':
        return Icons.euro;
      case 'GBP':
        return Icons.currency_pound;
      case 'JPY':
        return Icons.currency_yen;
      case 'CNY':
      case 'CNH':
        return Icons.currency_yuan;
      case 'RUB':
        return Icons.currency_ruble;
      case 'TRY':
        return Icons.currency_lira;
      case 'CHF':
        return Icons.currency_franc;
      case 'BTC':
        return Icons.currency_bitcoin;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String normalized = (code ?? '').trim().toUpperCase();
    final IconData? icon = _iconFor(normalized);
    debugPrint('[CurrencySymbolIcon] build -> input="$code", normalized="$normalized", icon=$icon, size=$size');
    if (icon != null) {
      return Icon(icon, size: size);
    }

    String symbol;
    try {
      symbol = NumberFormat.simpleCurrency(
        name: normalized.isEmpty ? 'INR' : normalized,
      ).currencySymbol;
    } catch (_) {
      symbol = '¤'; // Generic currency sign
    }
    debugPrint('[CurrencySymbolIcon] using text symbol "$symbol" for currency "$normalized"');

    final Color? color = IconTheme.of(context).color;
    return Text(
      symbol,
      style: TextStyle(
        fontSize: size * 0.9,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.0,
      ),
    );
  }
}
