import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/widgets/details/game_details.dart';
import 'package:espy/widgets/dialogs/search_dialog.dart';
import 'package:flutter/material.dart';

class GameDetailsPage extends Page {
  final LibraryEntry entry;

  GameDetailsPage({required this.entry}) : super(key: ValueKey(entry));

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (context) {
        return Actions(actions: {
          SearchIntent: CallbackAction<SearchIntent>(
              onInvoke: (intent) => SearchDialog.show(context)),
        }, child: GameDetails(entry));
      },
    );
  }
}
