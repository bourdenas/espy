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
  }) : super(key: key);

  final LibraryEntry libraryEntry;
  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    return AppConfigModel.isMobile(context)
        ? GameDetailsContentMobile(libraryEntry, gameEntry)
        : GameDetailsContentDesktop(libraryEntry, gameEntry);
  }
}
