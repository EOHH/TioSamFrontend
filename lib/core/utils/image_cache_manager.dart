import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class TioSamCacheManager {
  static const key = 'tiosam_image_cache';

  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7), // Borra fotos de hace más de una semana
      maxNrOfCacheObjects: 1000, // Límite estricto para no saturar el disco del celular
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}