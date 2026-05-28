import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  /// Recibe un archivo pesado y devuelve uno ultraligero sin perder calidad visual
  static Future<File> compressImage(File file, {int quality = 70}) async {
    try {
      final dir = await getTemporaryDirectory();
      // El formato de salida será JPG para máxima compatibilidad web/móvil
      final targetPath = '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1080, // Límite ideal para pantallas modernas sin derrochar píxeles
        minHeight: 1080,
      );

      if (result != null) {
        if (kDebugMode) {
          final originalSize = file.lengthSync() / 1024;
          final newSize = File(result.path).lengthSync() / 1024;
          print('📉 Compresión: de ${originalSize.toStringAsFixed(1)} KB a ${newSize.toStringAsFixed(1)} KB');
        }
        return File(result.path);
      }
      return file; // Si algo falla, devuelve la original para no interrumpir a tu usuario
    } catch (e) {
      if (kDebugMode) print("Error comprimiendo imagen: $e");
      return file;
    }
  }
}