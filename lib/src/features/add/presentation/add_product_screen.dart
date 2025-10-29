import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:provider/provider.dart';

import '../../../data/off/off_auth.dart';
import '../../../data/off/off_write_api.dart';
import 'widgets/add_photo_slot.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key, this.prefilledBarcode});

  final String? prefilledBarcode;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _categoriesCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();

  final Map<ImageField, String?> _thumbnails = {
    ImageField.FRONT: null,
    ImageField.INGREDIENTS: null,
    ImageField.NUTRITION: null,
    ImageField.PACKAGING: null,
  };

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledBarcode != null && widget.prefilledBarcode!.isNotEmpty) {
      _barcodeCtrl.text = widget.prefilledBarcode!;
    }
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _quantityCtrl.dispose();
    _categoriesCtrl.dispose();
    _ingredientsCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<OffAuth>();
    final offUser = auth.offUser;
    if (offUser == null) {
      setState(() => _error = 'Please sign in under Profile first.');
      return;
    }

    final barcode = _barcodeCtrl.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result = await OffWriteApi().createOrUpdate(
        user: offUser.userId,
        pass: offUser.password,
        barcode: barcode,
        name: _nameCtrl.text,
        brand: _brandCtrl.text,
        quantity: _quantityCtrl.text,
        categories: _categoriesCtrl.text,
        ingredientsText: _ingredientsCtrl.text,
      );
      if (!mounted) return;
      if (result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product saved')),
        );
        final encodedBarcode = Uri.encodeComponent(barcode);
        context.go('/product/$encodedBarcode');
      } else {
        setState(() => _error = result.message);
      }
    } catch (err) {
      if (mounted) setState(() => _error = err.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadImage(ImageField field, File file) async {
    final barcode = _barcodeCtrl.text.trim();
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a barcode first')),
      );
      return;
    }

    final auth = context.read<OffAuth>();
    final user = auth.offUser ?? const User(userId: 'anonymous', password: '');
    final sendImage = SendImage(
      barcode: barcode,
      imageField: field,
      imageUri: Uri.file(file.path),
    );
    final result = await OpenFoodAPIClient.addProductImage(user, sendImage);
    if (!mounted) return;
    if (result.status == 'status ok') {
      setState(() => _thumbnails[field] = file.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${field.prettyName} photo uploaded')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Upload failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final readOnlyBarcode =
        widget.prefilledBarcode != null && widget.prefilledBarcode!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Add product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _barcodeCtrl,
                readOnly: readOnlyBarcode,
                decoration: const InputDecoration(labelText: 'Barcode'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Barcode required' : null,
              ),
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
                controller: _quantityCtrl,
                decoration:
                    const InputDecoration(labelText: 'Quantity (e.g., 330 ml)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoriesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Categories (comma-separated)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ingredientsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Ingredients text'),
              ),
              const SizedBox(height: 20),
              Text('Photos', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AddPhotoSlot(
                    label: 'Front',
                    imageField: ImageField.FRONT,
                    thumbnailPath: _thumbnails[ImageField.FRONT],
                    onPicked: (file) => _uploadImage(ImageField.FRONT, file),
                  ),
                  AddPhotoSlot(
                    label: 'Ingredients',
                    imageField: ImageField.INGREDIENTS,
                    thumbnailPath: _thumbnails[ImageField.INGREDIENTS],
                    onPicked: (file) => _uploadImage(ImageField.INGREDIENTS, file),
                  ),
                  AddPhotoSlot(
                    label: 'Nutrition',
                    imageField: ImageField.NUTRITION,
                    thumbnailPath: _thumbnails[ImageField.NUTRITION],
                    onPicked: (file) => _uploadImage(ImageField.NUTRITION, file),
                  ),
                  AddPhotoSlot(
                    label: 'Packaging',
                    imageField: ImageField.PACKAGING,
                    thumbnailPath: _thumbnails[ImageField.PACKAGING],
                    onPicked: (file) => _uploadImage(ImageField.PACKAGING, file),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _handleSubmit,
                child: Text(_saving ? 'Submitting…' : 'Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on ImageField {
  String get prettyName {
    switch (this) {
      case ImageField.FRONT:
        return 'Front';
      case ImageField.INGREDIENTS:
        return 'Ingredients';
      case ImageField.NUTRITION:
        return 'Nutrition';
      case ImageField.PACKAGING:
        return 'Packaging';
      default:
        return name;
    }
  }
}
