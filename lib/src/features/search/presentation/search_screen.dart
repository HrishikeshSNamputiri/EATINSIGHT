import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/fooddb_repository.dart';
import '../../../data/prefs/prefs_repository.dart';
import '../../../routing/app_router.dart';
import '../../../data/models/product.dart';
import '../../product/presentation/product_screen.dart';
import 'search_result_tile.dart';
import 'search_tokens.dart';

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
  String? _country;
  bool _loading = false;
  bool _hasMore = false;
  int _page = 1;
  final int _pageSize = 20;
  final List<Product> _items = [];
  List<String> _tokens = const [];

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

  bool _looksLikeBarcode(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\\s+'), '');
    if (cleaned.isEmpty || !RegExp(r'^\\d+$').hasMatch(cleaned)) return false;
    final len = cleaned.length;
    return len == 8 || len == 12 || len == 13 || len == 14;
  }

  Future<void> _handleSubmit(String raw) async {
    final cleaned = raw.replaceAll(RegExp(r'\\s+'), '');
    if (_looksLikeBarcode(cleaned)) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductScreen(barcode: cleaned)),
      );
      return;
    }
    _startSearch(raw);
  }

  Map<String, String?> _parseTokens(String raw) {
    final parts = raw.split(RegExp(r'\\s+')).where((e) => e.isNotEmpty).toList();
    String? cat;
    String? brand;
    String? country;
    final leftovers = <String>[];
    for (final part in parts) {
      final lower = part.toLowerCase();
      if (lower.startsWith('cat:')) {
        cat = part.substring(4).trim();
      } else if (lower.startsWith('brand:')) {
        brand = part.substring(6).trim();
      } else if (lower.startsWith('country:')) {
        country = part.substring(8).trim();
      } else {
        leftovers.add(part);
      }
    }
    final q = leftovers.join(' ').trim();
    return {'q': q, 'cat': cat, 'brand': brand, 'country': country};
  }

  Future<void> _startSearch(String v) async {
    final raw = v.trim();
    if (raw.isEmpty) {
      setState(() {
        _current = '';
        _category = null;
        _brand = null;
        _country = null;
        _items.clear();
        _page = 1;
        _hasMore = false;
        _loading = false;
        _tokens = const [];
      });
      return;
    }
    final parsed = _parseTokens(raw);
    final query = parsed['q']?.trim() ?? '';
    final cat = parsed['cat']?.trim();
    final brand = parsed['brand']?.trim();
    final country = parsed['country']?.trim();
    if (query.isEmpty && (cat == null || cat.isEmpty) && (brand == null || brand.isEmpty) && (country == null || country.isEmpty)) {
      setState(() {
        _current = '';
        _category = null;
        _brand = null;
        _country = null;
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
      _country = country?.isEmpty ?? true ? null : country;
      _items.clear();
      _page = 1;
      _hasMore = false;
      _loading = true;
      _tokens = tokenize(query);
    });
    await _fetchMore(reset: true);
  }

  Future<void> _fetchMore({bool reset = false}) async {
    if (_loading && !reset) return;
    if (!reset) {
      setState(() => _loading = true);
    }
    final repo = context.read<FoodDbRepository>();
    final prefs = context.read<PrefsController>().prefs;
    final list = await repo.searchProducts(
      _current,
      page: _page,
      categoryEn: _category,
      brandEn: _brand,
      countryEn: _country,
      languageCode: prefs.language,
      countryCode: prefs.country,
      tokens: _tokens,
    );
    if (!mounted) return;
    final tokens = _tokens;
    final filtered = tokens.isEmpty
        ? list
        : list
            .where((p) => containsAllTokens(
                  haystackName: p.name ?? '',
                  haystackBrand: p.brand ?? '',
                  tokens: tokens,
                ))
            .toList();
    setState(() {
      _items.addAll(filtered);
      _page += 1;
      _hasMore = tokens.isEmpty && list.length >= _pageSize;
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
                hintText: 'Try "cola", "cat:chocolates", "brand:nestle", or "country:India"',
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
              onSubmitted: (value) => _handleSubmit(value),
            ),
          ),
          Builder(
            builder: (context) {
              final prefs = context.watch<PrefsController>().prefs;
              final segments = <String>[];
              if (prefs.country != null && prefs.country!.trim().isNotEmpty) {
                segments.add('country=${prefs.country!.trim()}');
              }
              if (prefs.language != null && prefs.language!.trim().isNotEmpty) {
                segments.add('lc=${prefs.language!.trim()}');
              }
              final tokens = _tokens;
              if (segments.isEmpty && tokens.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (segments.isNotEmpty)
                        Text(
                          'Applied preferences: ${segments.join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (tokens.isNotEmpty)
                        Text(
                          'Keywords: ${tokens.join(' · ')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: _buildResults(context, _tokens),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, List<String> tokens) {
    final hasQuery =
        _current.isNotEmpty || (_category != null) || (_brand != null) || (_country != null);
    if (!hasQuery) {
      return const Center(child: Text('Type to search'));
    }
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(child: Text('No results'));
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          );
        }
        final product = _items[index];
        return Column(
          children: [
            SearchResultTile(
              product: product,
              tokens: tokens,
              onTap: () => context.go(
                AppRoutes.product.replaceFirst(':barcode', product.barcode),
              ),
            ),
            const Divider(height: 0),
          ],
        );
      },
    );
  }
}
