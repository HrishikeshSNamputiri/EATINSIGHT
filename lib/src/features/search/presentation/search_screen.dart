import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/fooddb_repository.dart';
import '../../../data/models/product.dart';
import '../../../data/off/off_search_api.dart';
import '../../../data/prefs/lookup_tables.dart';
import '../../../data/prefs/prefs_repository.dart';
import '../../../data/prefs/user_prefs.dart';
import '../../../routing/app_router.dart';
import '../../product/presentation/product_screen.dart';
import '../data/search_history_store.dart';
import 'search_result_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

String? _countryNameForPrefs(UserPrefs prefs) {
  final String? code = prefs.country?.trim();
  if (code == null || code.isEmpty) {
    return null;
  }
  final CodeName match = kCountries.firstWhere(
    (CodeName entry) => entry.code.toLowerCase() == code.toLowerCase(),
    orElse: () => CodeName(code, code.toUpperCase()),
  );
  return match.name;
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.loadedCount,
    required this.totalCount,
    required this.worldMode,
    required this.countryName,
    required this.onToggleWorld,
  });

  final int loadedCount;
  final int totalCount;
  final bool worldMode;
  final String? countryName;
  final Future<void> Function() onToggleWorld;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int displayCount = totalCount > 0 ? totalCount : loadedCount;
    final String quantityLabel =
        '$displayCount product${displayCount == 1 ? '' : 's'}';
    final String subtitle = worldMode
        ? 'Showing worldwide results'
        : (countryName != null && countryName!.isNotEmpty)
            ? 'Showing results for $countryName'
            : 'Using your saved preferences';
    final String? detail = totalCount > 0 && loadedCount < totalCount
        ? 'Loaded $loadedCount of $totalCount'
        : null;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(
          quantityLabel,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: detail == null ? Text(subtitle) : Text('$subtitle\n$detail'),
        isThreeLine: detail != null,
        trailing: IconButton(
          icon: Icon(worldMode ? Icons.public_off : Icons.public),
          tooltip:
              worldMode ? 'Back to local results' : 'See worldwide results',
          onPressed: () {
            onToggleWorld();
          },
        ),
      ),
    );
  }
}

class _SearchScreenState extends State<SearchScreen> {
  static const int _pageSize = 20;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _resultsScroll = ScrollController();
  final SearchHistoryStore _historyStore = SearchHistoryStore();

  bool _loading = false;
  bool _hasMore = false;
  bool _worldMode = false;
  int _page = 1;
  int _totalCount = 0;
  String? _activeQuery;
  final List<Product> _items = <Product>[];
  List<String> _history = const <String>[];
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _resultsScroll.addListener(_onScroll);
    _loadHistory();
  }

  @override
  void dispose() {
    _resultsScroll.removeListener(_onScroll);
    _resultsScroll.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loading || _activeQuery == null) {
      return;
    }
    if (_resultsScroll.position.pixels >
        _resultsScroll.position.maxScrollExtent - 280) {
      _fetchMore();
    }
  }

  bool _looksLikeBarcode(String raw) {
    final String cleaned = raw.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty || !RegExp(r'^\d+$').hasMatch(cleaned)) {
      return false;
    }
    final int len = cleaned.length;
    return len == 8 || len == 12 || len == 13 || len == 14;
  }

  Future<void> _performSearch(String raw) async {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      _resetSearch();
      return;
    }
    final String cleaned = raw.replaceAll(RegExp(r'\s+'), '');
    if (_looksLikeBarcode(cleaned)) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductScreen(barcode: cleaned),
        ),
      );
      return;
    }

    setState(() {
      _activeQuery = trimmed;
      _page = 1;
      _hasMore = false;
      _loading = true;
      _items.clear();
      _worldMode = false;
      _totalCount = 0;
    });

    final List<String> entries = await _historyStore.add(trimmed);
    if (mounted) {
      setState(() {
        _history = entries;
      });
    }

    await _fetchMore(reset: true);
  }

  Future<void> _fetchMore({bool reset = false}) async {
    if (_loading && !reset) {
      return;
    }
    final String? query = _activeQuery;
    if (query == null || query.isEmpty) {
      return;
    }

    if (!reset) {
      setState(() => _loading = true);
    }

    final FoodDbRepository repo = context.read<FoodDbRepository>();
    final UserPrefs prefs = context.read<PrefsController>().prefs;
    final OffSearchResponse response = await repo.searchProducts(
      query,
      page: _page,
      languageCode: prefs.language,
      countryCode: prefs.country,
      world: _worldMode,
    );
    if (!mounted) {
      return;
    }

    final List<Product> newProducts = response.products;
    setState(() {
      _items.addAll(newProducts);
      _totalCount = response.totalCount;
      _page = response.page + 1;
      if (response.totalCount == 0) {
        _hasMore = newProducts.length >= _pageSize;
      } else {
        _hasMore = _items.length < response.totalCount;
      }
      _loading = false;
    });
  }

  void _resetSearch() {
    setState(() {
      _activeQuery = null;
      _items.clear();
      _page = 1;
      _hasMore = false;
      _loading = false;
      _worldMode = false;
      _totalCount = 0;
    });
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    final List<String> entries = await _historyStore.load();
    if (!mounted) return;
    setState(() {
      _history = entries;
      _historyLoading = false;
    });
  }

  Future<void> _removeHistoryEntry(String query) async {
    final List<String> entries = await _historyStore.remove(query);
    if (!mounted) return;
    setState(() => _history = entries);
  }

  Future<void> _handleClipboardPaste() async {
    final ClipboardData? data = await Clipboard.getData('text/plain');
    final String text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty')),
      );
      return;
    }
    _controller.text = text;
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    await _performSearch(text);
  }

  void _editHistory(String query) {
    _controller.text = query;
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    _focusNode.requestFocus();
  }

  Future<void> _setWorldMode(bool value) async {
    if (_activeQuery == null || _worldMode == value) {
      return;
    }
    setState(() {
      _worldMode = value;
      _page = 1;
      _items.clear();
      _hasMore = false;
      _loading = true;
      _totalCount = 0;
    });
    await _fetchMore(reset: true);
  }

  Future<void> _toggleWorldMode() => _setWorldMode(!_worldMode);

  Future<void> _refreshResults() async {
    if (_activeQuery == null) {
      return;
    }
    setState(() {
      _page = 1;
      _items.clear();
      _hasMore = false;
      _loading = true;
      _totalCount = 0;
    });
    await _fetchMore(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final UserPrefs prefs = context.watch<PrefsController>().prefs;
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: 'Search products',
                hintText: 'Type a product name or barcode',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? IconButton(
                        tooltip: 'Search',
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () => _performSearch(_controller.text),
                      )
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          _resetSearch();
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _performSearch,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _activeQuery == null
                ? const SizedBox.shrink()
                : _ContextChips(
                    worldMode: _worldMode,
                    onWorldModeChanged: _setWorldMode,
                    prefs: prefs,
                  ),
          ),
          Expanded(
            child:
                _activeQuery == null ? _buildHistory() : _buildResults(prefs),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final bool hasHistory = _history.isNotEmpty;
    final int itemCount = 1 + (hasHistory ? 1 + _history.length : 0);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return ListTile(
            leading: const Icon(Icons.paste),
            title: const Text('Search with clipboard'),
            onTap: _handleClipboardPaste,
          );
        }
        if (!hasHistory) {
          return const SizedBox.shrink();
        }
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'Recent searches',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          );
        }
        final String query = _history[index - 2];
        return Dismissible(
          key: Key(query),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _removeHistoryEntry(query),
          background: Container(
            color: Colors.redAccent,
            alignment: AlignmentDirectional.centerEnd,
            padding: const EdgeInsetsDirectional.only(end: 24),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            leading: const Icon(Icons.history),
            title: Text(query),
            onTap: () => _performSearch(query),
            trailing: IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'Edit query',
              onPressed: () => _editHistory(query),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResults(UserPrefs prefs) {
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      final String headline =
          'No results for "${_activeQuery ?? ''}" in your region.';
      return Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.search_off, size: 36),
                const SizedBox(height: 12),
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different keyword or broaden the scope.',
                  textAlign: TextAlign.center,
                ),
                if (!_worldMode) ...<Widget>[
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: _toggleWorldMode,
                    icon: const Icon(Icons.public),
                    label: const Text('Search worldwide instead'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refreshResults,
      child: ListView.builder(
        controller: _resultsScroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: _items.length + (_hasMore ? 1 : 0) + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: _ResultHeader(
                loadedCount: _items.length,
                totalCount: _totalCount,
                worldMode: _worldMode,
                countryName: _countryNameForPrefs(prefs),
                onToggleWorld: _toggleWorldMode,
              ),
            );
          }
          final int resultIndex = index - 1;
          if (resultIndex >= _items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : const SizedBox.shrink(),
            );
          }
          final Product product = _items[resultIndex];
          return Column(
            children: <Widget>[
              SearchResultTile(
                product: product,
                onTap: () => context.go(
                  AppRoutes.product.replaceFirst(':barcode', product.barcode),
                ),
              ),
              const SizedBox(height: 6),
            ],
          );
        },
      ),
    );
  }
}

class _ContextChips extends StatelessWidget {
  const _ContextChips({
    required this.worldMode,
    required this.onWorldModeChanged,
    required this.prefs,
  });

  final bool worldMode;
  final ValueChanged<bool> onWorldModeChanged;
  final UserPrefs prefs;

  @override
  Widget build(BuildContext context) {
    final String? country = _countryNameForPrefs(prefs);
    final String? language = prefs.language?.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ChoiceChip(
            label: const Text('Local'),
            selected: !worldMode,
            onSelected: (bool selected) {
              if (selected) onWorldModeChanged(false);
            },
          ),
          ChoiceChip(
            label: const Text('Worldwide'),
            selected: worldMode,
            onSelected: (bool selected) {
              if (selected) onWorldModeChanged(true);
            },
          ),
          if (!worldMode && country != null)
            InputChip(
              avatar: const Icon(Icons.flag_outlined, size: 18),
              label: Text(country),
              onPressed: null,
            ),
          if (language != null && language.isNotEmpty)
            InputChip(
              avatar: const Icon(Icons.language, size: 18),
              label: Text('Lang $language'),
              onPressed: null,
            ),
        ],
      ),
    );
  }
}
