import 'package:flutter/foundation.dart' show ChangeNotifier;

class AppConfig extends ChangeNotifier {
  double windowWidth = 0;

  get isMobile => windowWidth <= 800;
  get isNotMobile => windowWidth > 800;
}
