import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:provider/provider.dart';
import '../../../data/off/off_auth.dart';
import '../../../data/off/off_image_upload.dart';

class AddPhotoSheet extends StatefulWidget {
  final String barcode;
  const AddPhotoSheet({super.key, required this.barcode});

  @override
  State<AddPhotoSheet> createState() => _AddPhotoSheetState();
}

class _AddPhotoSheetState extends State<AddPhotoSheet> {
  final _picker = ImagePicker();
  ImageField _field = ImageField.FRONT;
  bool _busy = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final auth = context.read<OffAuth>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() { _error = null; });
    final x = await _picker.pickImage(source: source, imageQuality: 92, maxWidth: 2000);
    if (x == null) return;
    final file = File(x.path);

    final user = auth.offUser;
    if (user == null) {
      setState(() { _error = 'Please sign in under Profile first.'; });
      return;
    }

    setState(() => _busy = true);
    try {
      final res = await OffImageUpload.upload(
        user: user,
        barcode: widget.barcode,
        field: _field,
        file: file,
      );
      if (!mounted) return;
      if (res.ok) {
        navigator.pop(true); // signal success
        messenger.showSnackBar(
          SnackBar(content: Text('Photo uploaded (${_field.name.toLowerCase()}).')),
        );
      } else {
        setState(() { _error = res.message; });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<ImageField>>[
      const DropdownMenuItem(value: ImageField.FRONT, child: Text('Front')),
      const DropdownMenuItem(value: ImageField.INGREDIENTS, child: Text('Ingredients')),
      const DropdownMenuItem(value: ImageField.NUTRITION, child: Text('Nutrition')),
      const DropdownMenuItem(value: ImageField.PACKAGING, child: Text('Packaging')),
      const DropdownMenuItem(value: ImageField.OTHER, child: Text('Other')),
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Type:'),
              const SizedBox(width: 12),
              DropdownButton<ImageField>(
                value: _field,
                items: items,
                onChanged: _busy ? null : (v) => setState(() => _field = v ?? _field),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
