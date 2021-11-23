import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/scaffold/espy_scaffold.dart' show EspyScaffold;
import 'package:espy/widgets/dialogs/search_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            HomeIntent: CallbackAction<HomeIntent>(
                onInvoke: (intent) =>
                    context.read<EspyRouterDelegate>().showLibrary()),
          },
          child: EspyScaffold(),
        );
      },
    );
  }
}
