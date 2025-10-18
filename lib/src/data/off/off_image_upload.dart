import 'dart:io';
import 'package:openfoodfacts/openfoodfacts.dart';

class OffImageUploadResult {
  final bool ok;
  final String message;
  OffImageUploadResult(this.ok, this.message);
}

class OffImageUpload {
  static Future<OffImageUploadResult> upload({
    required User user,
    required String barcode,
    required ImageField field,
    required File file,
  }) async {
    try {
      final img = SendImage(
        barcode: barcode,
        imageField: field,
        imageUri: Uri.file(file.path),
      );
      final status = await OpenFoodAPIClient.addProductImage(
        user,
        img,
      );
      final ok = (status.status == 1 || status.status == '1');
      final msg = status.statusVerbose ?? (ok ? 'OK' : 'Upload failed');
      return OffImageUploadResult(ok, msg);
    } catch (e) {
      return OffImageUploadResult(false, e.toString());
    }
  }
}
