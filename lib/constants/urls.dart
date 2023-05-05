import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Urls {
  static final espyBackend = kIsWeb
      ? 'https://httpserver-fjxkoqq4wq-ew.a.run.app'
      // ? 'http://127.0.0.1:8080'
      : Platform.isAndroid
          // ? 'http://10.0.2.2:3030'
          ? 'https://httpserver-fjxkoqq4wq-ew.a.run.app'
          : 'https://httpserver-fjxkoqq4wq-ew.a.run.app';
  static const imageProvider = kIsWeb
      ? 'https://images.igdb.com/igdb/image/upload'
      // ? 'http://localhost:3030/images'
      : 'https://images.igdb.com/igdb/image/upload';
}
