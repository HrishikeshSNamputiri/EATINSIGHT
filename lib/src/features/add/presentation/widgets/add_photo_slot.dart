import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

/// Selects a photo for the given [imageField] using camera or gallery, then
/// forwards the resulting [File] to [onPicked].
class AddPhotoSlot extends StatelessWidget {
  const AddPhotoSlot({
    super.key,
    required this.label,
    required this.imageField,
    required this.onPicked,
    this.thumbnailPath,
  });

  final String label;
  final ImageField imageField;
  final Future<void> Function(File file) onPicked;
  final String? thumbnailPath;

  Future<void> _chooseSource(BuildContext context) async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from files'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final picker = ImagePicker();
    final XFile? xfile = await picker.pickImage(
      source: choice,
      imageQuality: 92,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (xfile == null) return;
    await onPicked(File(xfile.path));
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${imageField.name.toLowerCase()} photo',
      child: GestureDetector(
        onTap: () => _chooseSource(context),
        child: Container(
          width: 140,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: thumbnailPath == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined),
                    const SizedBox(height: 8),
                    Text(label, textAlign: TextAlign.center),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(thumbnailPath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
        ),
      ),
    );
  }
}
