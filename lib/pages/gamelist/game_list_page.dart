import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/remote_library_model.dart';
import 'package:espy/pages/gamelist/game_grid_view.dart';
import 'package:espy/pages/gamelist/game_list_view.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameListPage extends StatefulWidget {
  const GameListPage({Key? key, required this.filter}) : super(key: key);

  final LibraryFilter filter;

  @override
  State<GameListPage> createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  @override
  Widget build(BuildContext context) {
    final entries =
        context.watch<LibraryEntriesModel>().filter(widget.filter).toList();

    if (!fetched) {
      RemoteLibraryModel.fromFilter(widget.filter).then((value) => setState(() {
            _remoteGames = value;
            fetched = true;
          }));
    }

    final Set<int> entryIds = Set.from(entries.map((e) => e.id));
    entries.addAll(_remoteGames.where((e) => !entryIds.contains(e.id)));
    entries.sort((a, b) => -a.releaseDate.compareTo(b.releaseDate));

    return LibraryContent(entries: entries, filter: widget.filter);
  }

  bool fetched = false;
  List<LibraryEntry> _remoteGames = [];
}

class LibraryContent extends StatelessWidget {
  const LibraryContent({
    Key? key,
    required this.entries,
    required this.filter,
  }) : super(key: key);

  final List<LibraryEntry> entries;
  final LibraryFilter filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: badges.Badge(
          badgeContent: Text('${entries.length}'),
          badgeStyle: const badges.BadgeStyle(
            shape: badges.BadgeShape.circle,
            badgeColor: Colors.deepPurple,
            padding: EdgeInsets.all(8),
          ),
          position: badges.BadgePosition.center(),
          child: Container(),
        ),
        title: GameChipsFilter(filter),
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0.0,
      ),
      body: context.watch<AppConfigModel>().libraryLayout.value ==
              LibraryLayout.grid
          ? GameGridView(entries: entries)
          : GameListView(entries: entries),
    );
  }
}
