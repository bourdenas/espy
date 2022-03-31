import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/details/game_details_mobile.dart';
import 'package:espy/pages/details/game_details_desktop.dart';
import 'package:flutter/material.dart';

class GameDetailsContent extends StatelessWidget {
  const GameDetailsContent({
    Key? key,
    required this.libraryEntry,
    required this.gameEntry,
    required this.childPath,
  }) : super(key: key);

  final LibraryEntry libraryEntry;
  final GameEntry gameEntry;
  final List<String> childPath;

  @override
  Widget build(BuildContext context) {
    var shownEntry = gameEntry;
    for (final id in childPath) {
      final gameId = int.tryParse(id) ?? 0;

      shownEntry = [
        shownEntry.expansions,
        shownEntry.dlcs,
        shownEntry.remakes,
        shownEntry.remasters,
      ].expand((e) => e).firstWhere((e) => e.id == gameId);
    }

    return AppConfigModel.isMobile(context)
        ? GameDetailsContentMobile(
            libraryEntry: libraryEntry,
            gameEntry: shownEntry,
            childPath: childPath,
          )
        : GameDetailsContentDesktop(
            libraryEntry: libraryEntry,
            gameEntry: shownEntry,
            childPath: childPath,
          );
  }
}
