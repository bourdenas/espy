import 'package:espy/widgets/scaffold/espy_scaffold.dart' show EspyScaffold;
import 'package:flutter/material.dart';

class GameLibraryPage extends Page {
  GameLibraryPage() : super(key: ValueKey('GameLibraryPage'));

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (context) {
        return EspyScaffold();
      },
    );
  }
}
