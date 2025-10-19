import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/off/off_auth.dart';
import '../../../data/off/off_write_api.dart';
import '../../../data/models/product.dart';

class EditProductSheet extends StatefulWidget {
  final Product product;
  const EditProductSheet({super.key, required this.product});

  @override
  State<EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<EditProductSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _qtyCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name ?? '');
    _brandCtrl = TextEditingController(text: widget.product.brand ?? '');
    _qtyCtrl = TextEditingController(text: widget.product.quantity ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<OffAuth>();
    final offUser = auth.offUser;
    if (offUser == null) {
      setState(() => _error = 'Please sign in under Profile first.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final res = await OffWriteApi().createOrUpdate(
        user: offUser.userId,
        pass: offUser.password,
        barcode: widget.product.barcode,
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        quantity: _qtyCtrl.text.trim().isEmpty ? null : _qtyCtrl.text.trim(),
      );
      if (!mounted) return;
      if (res.ok) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes submitted. Pull to refresh.')),
        );
      } else {
        setState(() => _error = res.message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Barcode: ${widget.product.barcode}'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brandCtrl,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qtyCtrl,
              decoration: const InputDecoration(labelText: 'Quantity (e.g., 330 ml)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: Text(_saving ? 'Submitting...' : 'Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
