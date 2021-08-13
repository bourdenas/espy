import 'package:flutter/material.dart';

class Config {
  static bool isMobile(BoxConstraints constraints) =>
      constraints.maxWidth <= 800;

  static bool isNotMobile(BoxConstraints constraints) =>
      constraints.maxWidth > 800;
}
