import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class CacheMapa {
  static Future<BuiltInMapCachingProvider> preparar() async {
    final pasta = await getApplicationSupportDirectory();
    final cache = Directory(join(pasta.path, 'imagens_mapa'));
    await cache.create(recursive: true);
    // Mantém os prazos definidos pelos cabeçalhos HTTP do provedor.
    return BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: cache.path,
      maxCacheSize: 100000000,
    );
  }
}
