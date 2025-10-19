import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/prefs/prefs_repository.dart';
import '../../../data/prefs/user_prefs.dart';
import '../../../data/prefs/lookup_tables.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late PrefsController _ctrl;
  String? _countryCode;
  String? _languageCode;
  String? _currencyCode;
  bool _haptics = true;
  bool _scannerVibration = true;
  bool _keepScreenOn = false;

  @override
  void initState() {
    super.initState();
    _ctrl = context.read<PrefsController>();
    _ctrl.addListener(_onChange);
    _ctrl.load();
  }

  void _onChange() {
    final p = _ctrl.prefs;
    _countryCode = p.country;
    _languageCode = p.language;
    _currencyCode = p.currency;
    _haptics = p.haptics;
    _scannerVibration = p.scannerVibration;
    _keepScreenOn = p.keepScreenOn;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChange);
    super.dispose();
  }

  Future<void> _save() async {
    final UserPrefs next = _ctrl.prefs.copyWith(
      country: (_countryCode == null || _countryCode!.isEmpty) ? null : _countryCode,
      language: (_languageCode == null || _languageCode!.isEmpty) ? null : _languageCode,
      currency: (_currencyCode == null || _currencyCode!.isEmpty) ? null : _currencyCode,
      haptics: _haptics,
      scannerVibration: _scannerVibration,
      keepScreenOn: _keepScreenOn,
    );
    await _ctrl.update(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences saved.')));
    Navigator.of(context).maybePop();
  }

  Future<void> _pickFrom(
    List<CodeName> source,
    String title,
    String? selected,
    void Function(String?) onSelected,
  ) async {
    final ctrl = TextEditingController();
    List<CodeName> filtered = List.of(source);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(ctx).padding.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search…',
                  ),
                  onChanged: (q) {
                    final qq = q.trim().toLowerCase();
                    setState(() {
                      filtered = source
                          .where(
                            (e) =>
                                e.name.toLowerCase().contains(qq) ||
                                e.code.toLowerCase().contains(qq),
                          )
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      final isSel =
                          selected != null && selected.toLowerCase() == item.code.toLowerCase();
                      return ListTile(
                        dense: true,
                        title: Text(item.name),
                        subtitle: Text(item.code),
                        trailing: isSel ? const Icon(Icons.check) : null,
                        onTap: () {
                          onSelected(item.code);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        onSelected(null);
                        Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<PrefsController>().loading;
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (loading) const LinearProgressIndicator(),
          const Text('General', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Country'),
                  subtitle: Text(
                    _countryCode == null
                        ? 'Not set'
                        : '${kCountries.firstWhere((e) => e.code == _countryCode, orElse: () => CodeName(_countryCode!, _countryCode!)).name} ($_countryCode)',
                  ),
                  trailing: FilledButton(
                    onPressed: () => _pickFrom(
                      kCountries,
                      'Select country',
                      _countryCode,
                      (c) => setState(() => _countryCode = c),
                    ),
                    child: const Text('Select'),
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text('Language'),
                  subtitle: Text(
                    _languageCode == null
                        ? 'Not set'
                        : '${kLanguages.firstWhere((e) => e.code == _languageCode, orElse: () => CodeName(_languageCode!, _languageCode!)).name} ($_languageCode)',
                  ),
                  trailing: FilledButton(
                    onPressed: () => _pickFrom(
                      kLanguages,
                      'Select language',
                      _languageCode,
                      (c) => setState(() => _languageCode = c),
                    ),
                    child: const Text('Select'),
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text('Currency'),
                  subtitle: Text(
                    _currencyCode == null
                        ? 'Not set'
                        : '${kCurrencies.firstWhere((e) => e.code == _currencyCode, orElse: () => CodeName(_currencyCode!, _currencyCode!)).name} ($_currencyCode)',
                  ),
                  trailing: FilledButton(
                    onPressed: () => _pickFrom(
                      kCurrencies,
                      'Select currency',
                      _currencyCode,
                      (c) => setState(() => _currencyCode = c),
                    ),
                    child: const Text('Select'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Interaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SwitchListTile(
            value: _haptics,
            onChanged: (v) => setState(() => _haptics = v),
            title: const Text('Haptics'),
            subtitle: const Text('Vibration and gentle feedback where supported'),
          ),
          SwitchListTile(
            value: _scannerVibration,
            onChanged: (v) => setState(() => _scannerVibration = v),
            title: const Text('Scanner vibration'),
            subtitle: const Text('Vibrate when a barcode is detected'),
          ),
          SwitchListTile(
            value: _keepScreenOn,
            onChanged: (v) => setState(() => _keepScreenOn = v),
            title: const Text('Keep screen on while scanning'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: loading ? null : _save,
            child: Text(loading ? 'Saving…' : 'Save'),
          ),
        ],
      ),
    );
  }
}
