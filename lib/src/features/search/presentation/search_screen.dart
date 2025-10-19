import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/fooddb_repository.dart';
import '../../../routing/app_router.dart';
import '../../../data/models/product.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _q = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  String _current = '';
  String? _category;
  String? _brand;
  bool _loading = false;
  bool _hasMore = false;
  int _page = 1;
  final int _pageSize = 20;
  final List<Product> _items = [];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 280) {
      _fetchMore();
    }
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _startSearch(v);
    });
  }

  bool _looksLikeBarcode(String s) => RegExp(r'^\\d{8,14}$').hasMatch(s);

  Map<String, String?> _parseTokens(String raw) {
    final parts = raw.split(RegExp(r'\\s+')).where((e) => e.isNotEmpty).toList();
    String? cat;
    String? brand;
    final leftovers = <String>[];
    for (final part in parts) {
      final lower = part.toLowerCase();
      if (lower.startsWith('cat:')) {
        cat = part.substring(4).trim();
      } else if (lower.startsWith('brand:')) {
        brand = part.substring(6).trim();
      } else {
        leftovers.add(part);
      }
    }
    final q = leftovers.join(' ').trim();
    return {'q': q, 'cat': cat, 'brand': brand};
  }

  Future<void> _startSearch(String v) async {
    final raw = v.trim();
    if (raw.isEmpty) {
      setState(() {
        _current = '';
        _category = null;
        _brand = null;
        _items.clear();
        _page = 1;
        _hasMore = false;
        _loading = false;
      });
      return;
    }
    if (_looksLikeBarcode(raw)) {
      if (!mounted) return;
      context.go(AppRoutes.product.replaceFirst(':barcode', raw));
      return;
    }
    final parsed = _parseTokens(raw);
    final query = parsed['q']?.trim() ?? '';
    final cat = parsed['cat']?.trim();
    final brand = parsed['brand']?.trim();
    if (query.isEmpty && (cat == null || cat.isEmpty) && (brand == null || brand.isEmpty)) {
      setState(() {
        _current = '';
        _category = null;
        _brand = null;
        _items.clear();
        _page = 1;
        _hasMore = false;
        _loading = false;
      });
      return;
    }
    setState(() {
      _current = query;
      _category = cat?.isEmpty ?? true ? null : cat;
      _brand = brand?.isEmpty ?? true ? null : brand;
      _items.clear();
      _page = 1;
      _hasMore = false;
      _loading = true;
    });
    await _fetchMore(reset: true);
  }

  Future<void> _fetchMore({bool reset = false}) async {
    if (_loading && !reset) return;
    if (!reset) {
      setState(() => _loading = true);
    }
    final repo = context.read<FoodDbRepository>();
    final list = await repo.searchProducts(
      _current,
      page: _page,
      categoryEn: _category,
      brandEn: _brand,
    );
    if (!mounted) return;
    setState(() {
      _items.addAll(list);
      _page += 1;
      _hasMore = list.length >= _pageSize;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _q,
              decoration: InputDecoration(
                labelText: 'Search products',
                hintText: 'Try "cola", "cat:chocolates", or "brand:nestle"',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: (_current.isNotEmpty || _q.text.isNotEmpty)
                    ? IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          _q.clear();
                          _startSearch('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: _startSearch,
            ),
          ),
          Expanded(
            child: _buildResults(context),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final hasQuery =
        _current.isNotEmpty || (_category != null) || (_brand != null);
    if (!hasQuery) {
      return const Center(child: Text('Type to search'));
    }
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(child: Text('No results'));
    }
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      itemBuilder: (context, i) {
        if (i == _items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          );
        }
        final p = _items[i];
        return ListTile(
          leading: _Thumb(url: p.imageUrl),
          title: Text(p.name ?? 'Unnamed product'),
          subtitle: Text(p.brand ?? '—'),
          onTap: () => context.go(
            AppRoutes.product.replaceFirst(':barcode', p.barcode),
          ),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemCount: _items.length + 1,
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({required this.url});
  @override
  Widget build(BuildContext context) {
    const w = 56.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: (url == null || url!.isEmpty)
          ? Container(
              width: w,
              height: w,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.image_not_supported),
            )
          : Image.network(url!, width: w, height: w, fit: BoxFit.cover),
    );
  }
}
