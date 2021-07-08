import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/widgets/scaffold/espy_scaffold.dart' show EspyScaffold;
import 'package:espy/widgets/dialogs/search_dialog.dart';
import 'package:flutter/material.dart';

class GameLibraryPage extends Page {
  GameLibraryPage() : super(key: ValueKey('GameLibraryPage'));

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (context) {
        return Actions(
          actions: {
            SearchIntent: CallbackAction<SearchIntent>(
                onInvoke: (intent) => SearchDialog.show(context)),
          },
          child: EspyScaffold(),
        );
      },
    );
  }
}
