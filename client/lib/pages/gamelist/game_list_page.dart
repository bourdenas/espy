import 'package:espy/modules/intents/home_intent.dart';
import 'package:espy/modules/intents/search_intent.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/pages/gamelist/game_grid_view.dart';
import 'package:espy/pages/gamelist/game_list_view.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/src/provider.dart';

class GameListPage extends StatefulWidget {
  const GameListPage({required this.filter});

  final LibraryFilter filter;

  @override
  _GameListPageState createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  @override
  Widget build(BuildContext context) {
    final entries =
        context.watch<GameEntriesModel>().getEntries(widget.filter).toList();

    return Actions(
      actions: {
        SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) => context.pushNamed('search')),
        HomeIntent: CallbackAction<HomeIntent>(
            onInvoke: (intent) => context.goNamed('home')),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: GameChipsFilter(widget.filter),
            backgroundColor: Colors.black.withOpacity(0.6),
            elevation: 0.0,
          ),
          body: context.watch<AppConfigModel>().libraryLayout ==
                  LibraryLayout.GRID
              ? GameGridView(entries: entries)
              : GameListView(entries: entries),
        ),
      ),
    );
  }
}
