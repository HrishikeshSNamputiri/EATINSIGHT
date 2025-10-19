import 'package:flutter/material.dart';
import '../../../data/models/product.dart';

class SearchResultTile extends StatelessWidget {
  final Product product;
  final List<String> tokens;
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.product,
    required this.tokens,
    required this.onTap,
  });

  TextSpan _buildHighlightedSpan(String text, TextStyle? baseStyle) {
    if (text.isEmpty || tokens.isEmpty) {
      return TextSpan(text: text, style: baseStyle);
    }
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    int index = 0;
    while (index < text.length) {
      int matchLength = 0;
      for (final token in tokens) {
        if (token.isEmpty) continue;
        if (lower.startsWith(token, index) && token.length > matchLength) {
          matchLength = token.length;
        }
      }
      if (matchLength == 0) {
        spans.add(TextSpan(text: text[index], style: baseStyle));
        index += 1;
      } else {
        spans.add(TextSpan(
          text: text.substring(index, index + matchLength),
          style: baseStyle?.copyWith(fontWeight: FontWeight.bold),
        ));
        index += matchLength;
      }
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameStyle = theme.textTheme.bodyLarge;
    final brandStyle = theme.textTheme.bodyMedium;
    final name = product.name ?? 'Unnamed product';
    final brand = product.brand ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _ResultThumbnail(url: product.imageUrl),
      title: RichText(
        text: _buildHighlightedSpan(name, nameStyle),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: brand.isEmpty
          ? null
          : RichText(
              text: _buildHighlightedSpan(brand, brandStyle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _ResultThumbnail extends StatelessWidget {
  final String? url;
  const _ResultThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    const size = 52.0;
    if (url == null || url!.isEmpty) {
      final color = Theme.of(context).colorScheme.surfaceContainerHighest;
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: color,
        child: const Icon(Icons.inventory_2, size: 24),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(url!, width: size, height: size, fit: BoxFit.cover),
    );
  }
}
