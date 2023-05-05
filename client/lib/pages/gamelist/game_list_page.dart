import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/pages/gamelist/game_grid_view.dart';
import 'package:espy/pages/gamelist/game_list_view.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:flutter/material.dart';
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
        context.watch<GameEntriesModel>().filter(widget.filter).toList();

    return Scaffold(
      appBar: AppBar(
        leading: badges.Badge(
          badgeContent: Text('${entries.length}'),
          badgeStyle: badges.BadgeStyle(
            shape: badges.BadgeShape.instagram,
            badgeColor: Colors.deepPurple,
            padding: EdgeInsets.all(8),
          ),
          position: badges.BadgePosition.center(),
          child: Container(),
        ),
        title: GameChipsFilter(widget.filter),
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0.0,
      ),
      body: context.watch<AppConfigModel>().libraryLayout.value ==
              LibraryLayout.GRID
          ? GameGridView(entries: entries)
          : GameListView(entries: entries),
    );
  }
}
