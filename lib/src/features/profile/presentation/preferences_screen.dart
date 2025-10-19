import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/prefs/prefs_repository.dart';
import '../../../data/prefs/user_prefs.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late PrefsController _ctrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _langCtrl;
  late TextEditingController _currencyCtrl;
  bool _haptics = true;
  bool _scannerVibration = true;
  bool _keepScreenOn = false;

  @override
  void initState() {
    super.initState();
    _ctrl = context.read<PrefsController>();
    _countryCtrl = TextEditingController();
    _langCtrl = TextEditingController();
    _currencyCtrl = TextEditingController();
    _ctrl.addListener(_onChange);
    _ctrl.load();
  }

  void _onChange() {
    final p = _ctrl.prefs;
    _countryCtrl.text = p.country ?? '';
    _langCtrl.text = p.language ?? '';
    _currencyCtrl.text = p.currency ?? '';
    _haptics = p.haptics;
    _scannerVibration = p.scannerVibration;
    _keepScreenOn = p.keepScreenOn;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChange);
    _countryCtrl.dispose();
    _langCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final UserPrefs next = _ctrl.prefs.copyWith(
      country: _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
      language: _langCtrl.text.trim().isEmpty ? null : _langCtrl.text.trim(),
      currency: _currencyCtrl.text.trim().isEmpty ? null : _currencyCtrl.text.trim(),
      haptics: _haptics,
      scannerVibration: _scannerVibration,
      keepScreenOn: _keepScreenOn,
    );
    await _ctrl.update(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences saved.')));
    Navigator.of(context).maybePop();
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
          TextField(
            controller: _countryCtrl,
            decoration: const InputDecoration(
              labelText: 'Country code (e.g., in, fr)',
              helperText: 'Optional default for search & product fetch',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _langCtrl,
            decoration: const InputDecoration(
              labelText: 'Language code (e.g., en)',
              helperText: 'Optional preference for texts',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _currencyCtrl,
            decoration: const InputDecoration(
              labelText: 'Currency (e.g., INR, EUR)',
              helperText: 'Optional currency for prices',
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
