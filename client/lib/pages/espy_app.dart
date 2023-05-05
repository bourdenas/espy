import 'package:espy/pages/espy_router.dart';
import 'package:flutter/material.dart';

class EspyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _EspyAppState();
}

class _EspyAppState extends State<EspyApp> {
  @override
  Widget build(BuildContext context) {
    return EspyRouter();
  }
}
