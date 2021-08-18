import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/material.dart';

class AppConfig extends ChangeNotifier {
  double windowWidth = 0;

  get isMobile => windowWidth <= 800;
  get isNotMobile => windowWidth > 800;

  get tagsTitleBar => false;

  get theme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: backgrounColour,
        backgroundColor: backgrounColour,
      );

  get foregroundColour => Color(0xFF66A3BB);
  get backgrounColour => Color(0xFF253A47);
}
