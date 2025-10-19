import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/off/off_auth.dart';
import '../../../data/prefs/prefs_repository.dart';
import '../../../data/robotoff/robotoff_api.dart';

class RobotoffQuestionsSheet extends StatefulWidget {
  final String barcode;
  const RobotoffQuestionsSheet({super.key, required this.barcode});

  @override
  State<RobotoffQuestionsSheet> createState() => _RobotoffQuestionsSheetState();
}

class _RobotoffQuestionsSheetState extends State<RobotoffQuestionsSheet> {
  late final RobotoffApi _api;
  bool _loading = true;
  String? _error;
  List<RoboQuestion> _questions = const [];

  @override
  void initState() {
    super.initState();
    _api = RobotoffApi();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = context.read<PrefsController>().prefs;
      final lang = (prefs.language ?? 'en').trim().isEmpty ? 'en' : prefs.language!.trim();
      final qs = await _api.fetchQuestions(widget.barcode, lang: lang);
      if (!mounted) return;
      setState(() => _questions = qs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<OffAuth>();
    final loggedIn = auth.isLoggedIn;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Questions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (!_loading && _error == null && _questions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No questions for this product.'),
              ),
            if (_questions.isNotEmpty)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    return ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: Text(q.question),
                      subtitle: q.sourceImageUrl != null ? Text(q.sourceImageUrl!) : null,
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemCount: _questions.length,
                ),
              ),
            if (!loggedIn)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Sign in to answer questions.'),
              ),
          ],
        ),
      ),
    );
  }
}
