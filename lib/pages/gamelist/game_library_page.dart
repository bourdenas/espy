import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/remote_library_model.dart';
import 'package:espy/pages/gamelist/game_grid_view.dart';
import 'package:espy/pages/gamelist/game_list_view.dart';
import 'package:espy/widgets/gametags/game_chips_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameLibraryPage extends StatefulWidget {
  const GameLibraryPage({Key? key, required this.filter}) : super(key: key);

  final LibraryFilter filter;

  @override
  State<GameLibraryPage> createState() => _GameLibraryPageState();
}

class _GameLibraryPageState extends State<GameLibraryPage> {
  @override
  Widget build(BuildContext context) {
    final entries =
        context.watch<LibraryEntriesModel>().filter(widget.filter).toList();

    final appConfig = context.watch<AppConfigModel>();

    if (!fetched && appConfig.fetchRemote.value) {
      RemoteLibraryModel.fromFilter(
        widget.filter,
        includeExpansions: appConfig.showExpansions.value,
      ).then((value) => setState(() {
            _remoteGames = value;
            fetched = true;
          }));
    }

    final Set<int> entryIds = Set.from(entries.map((e) => e.id));
    if (appConfig.fetchRemote.value) {
      entries.addAll(_remoteGames.where((e) => !entryIds.contains(e.id)));
    }

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
    final appConfig = context.watch<AppConfigModel>();
    return Scaffold(
      appBar: AppBar(
        leading: badges.Badge(
          badgeContent: Text(
            '${entries.length}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          badgeStyle: badges.BadgeStyle(
            shape: badges.BadgeShape.circle,
            badgeColor: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.all(8),
          ),
          position: badges.BadgePosition.center(),
          child: Container(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GameChipsFilterBar(filter),
            Row(
              children: [
                Text(
                  'Expansions',
                  style: Theme.of(context).textTheme.bodyLarge!,
                ),
                const SizedBox(width: 8),
                Switch(
                  value: appConfig.showExpansions.value,
                  onChanged: (selected) =>
                      appConfig.showExpansions.value = selected,
                ),
                const SizedBox(width: 16),
                Text(
                  'External',
                  style: Theme.of(context).textTheme.bodyLarge!,
                ),
                const SizedBox(width: 8),
                Switch(
                  value: appConfig.fetchRemote.value,
                  onChanged: (selected) =>
                      appConfig.fetchRemote.value = selected,
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0.0,
      ),
      body: appConfig.libraryLayout.value == LibraryLayout.grid
          ? GameGridView(entries: entries)
          : GameListView(entries: entries),
    );
  }
}
