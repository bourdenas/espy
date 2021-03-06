import 'package:espy/modules/screens/espy_home.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(EspyApp());
}

class EspyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'espy',
      theme: ThemeData.dark(),
      home: EspyHome(title: 'espy'),
    );
  }
}
