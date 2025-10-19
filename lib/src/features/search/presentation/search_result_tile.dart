import 'package:flutter/material.dart';
import '../../../data/models/product.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String name = product.name?.trim().isNotEmpty == true
        ? product.name!.trim()
        : 'Unnamed product';
    final String? brand =
        product.brand?.trim().isNotEmpty == true ? product.brand!.trim() : null;
    final String? quantity =
        product.quantity?.trim().isNotEmpty == true ? product.quantity : null;
    final String? grade = product.nutritionGrade?.trim().isNotEmpty == true
        ? product.nutritionGrade!.trim().toUpperCase()
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Thumbnail(url: product.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (brand != null || quantity != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: <Widget>[
                          if (brand != null)
                            Text(
                              brand,
                              style: theme.textTheme.bodyMedium,
                            ),
                          if (quantity != null)
                            Text(
                              quantity,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                        ],
                      ),
                    ],
                    if (grade != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _NutritionBadge(grade: grade),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const double size = 64;
    final BorderRadius radius = BorderRadius.circular(12);
    if (url == null || url!.isEmpty) {
      final Color color = Theme.of(context).colorScheme.surfaceContainerHighest;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
        ),
        child: const Icon(Icons.inventory_2, size: 26),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _NutritionBadge extends StatelessWidget {
  const _NutritionBadge({required this.grade});

  final String grade;

  Color _backgroundColor(BuildContext context) {
    switch (grade) {
      case 'A':
        return Colors.green.shade500;
      case 'B':
        return Colors.lightGreen.shade600;
      case 'C':
        return Colors.orange.shade600;
      case 'D':
        return Colors.deepOrange.shade700;
      case 'E':
        return Colors.red.shade700;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = _backgroundColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Nutri-Score $grade',
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: Colors.white),
      ),
    );
  }
}
