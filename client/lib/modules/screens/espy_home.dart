import 'package:espy/widgets/espy_game_grid.dart' show EspyGameGrid;
import 'package:espy/widgets/espy_scaffold.dart' show EspyScaffold;
import 'package:flutter/material.dart';

class GameLibraryPage extends Page {
  GameLibraryPage() : super(key: ValueKey('GameLibraryPage'));

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (BuildContext context) {
        return EspyScaffold(
          body: EspyGameGrid(),
        );
      },
    );
  }
}
