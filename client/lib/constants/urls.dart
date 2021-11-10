import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Urls {
  static final espyBackend = kIsWeb
      ? 'http://localhost:3030'
      : Platform.isAndroid
          ? 'http://10.0.2.2:3030'
          : 'http://localhost:3030';
  static final imageProvider = kIsWeb
      ? 'https://images.igdb.com/igdb/image/upload'
      // ? 'http://localhost:3030/images'
      : 'https://images.igdb.com/igdb/image/upload';
}
