import 'package:espy/modules/dialogs/search/search_dialog.dart';
import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/pages/gamelist/game_list_view.dart';
import 'package:espy/pages/gamelist/game_grid_view.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class GameListPage extends StatefulWidget {
  const GameListPage({required this.filter});

  final String filter;

  @override
  _GameListPageState createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  @override
  Widget build(BuildContext context) {
    final filter = LibraryFilter.decode(widget.filter);
    final entries =
        context.watch<GameEntriesModel>().getEntries(filter).toList();

    return Actions(
      actions: {
        SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) => SearchDialog.show(context)),
        HomeIntent: CallbackAction<HomeIntent>(onInvoke: (intent) {
          Navigator.pushNamed(context, '/home');
        }),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: GameChipsFilter(filter),
            backgroundColor: Colors.black.withOpacity(0.6),
            elevation: 0.0,
          ),
          body: AppConfigModel.isMobile(context)
              ? GameListView(entries: entries)
              : GameGridView(entries: entries),
        ),
      ),
    );
  }
}
