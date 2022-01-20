// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:espy/pages/espy_material_app.dart';
import 'package:flutter/material.dart';

class EspyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EspyAppState();
}

class _EspyAppState extends State<EspyApp> {
  @override
  void initState() {
    super.initState();

    // Prevent default event handler
    document.onContextMenu.listen((event) => event.preventDefault());
  }

  @override
  Widget build(BuildContext context) {
    return EspyMaterialApp();
  }
}
