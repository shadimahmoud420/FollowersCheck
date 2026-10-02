import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// ضغط الصور قبل الرفع: الإنترنت في غزة ضعيف ومكلف.
/// الهدف ~100-200KB للصورة بدقة كافية للعرض على الهاتف.
class ImageCompressor {
  static const maxSide = 1280;
  static const quality = 70;

  static Future<Uint8List> compress(XFile file) async {
    if (kIsWeb) return file.readAsBytes();
    final result = await FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: maxSide,
      minHeight: maxSide,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false, // إزالة بيانات الموقع من الصورة
    );
    return result ?? await file.readAsBytes();
  }
}
