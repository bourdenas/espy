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

    final appConfig = context.read<AppConfigModel>();
    final entries =
        context.watch<GameEntriesModel>().getEntries(filter).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: GameChipsFilter(filter),
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0.0,
      ),
      body: appConfig.isMobile(context)
          ? GameListView(entries: entries)
          : GameGridView(entries: entries),
    );
  }
}
