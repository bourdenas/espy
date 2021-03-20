import 'package:espy/widgets/espy_scaffold.dart' show EspyScaffold;
import 'package:espy/widgets/game_library.dart' show GameLibrary;
import 'package:flutter/material.dart';

class GameLibraryPage extends Page {
  GameLibraryPage() : super(key: ValueKey('GameLibraryPage'));

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (BuildContext context) {
        return EspyScaffold(
          body: GameLibrary(),
        );
      },
    );
  }
}
