import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/remote_library_model.dart';
import 'package:espy/pages/library/library_entries_view.dart';
import 'package:espy/widgets/gametags/game_chips_filter_bar.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<LibraryFilterModel>().filter;
    final libraryView = context.watch<LibraryEntriesModel>().filter(filter);

    final appConfig = context.watch<AppConfigModel>();
    return Scaffold(
      appBar: libraryHeader(context, appConfig, libraryView, filter),
      body: libraryBody(libraryView),
    );
  }

  CustomScrollView libraryBody(LibraryView libraryView) {
    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        if (!libraryView.hasGroups)
          LibraryEntriesView(
            entries: libraryView.all,
          )
        else ...[
          for (final (label, entries) in libraryView.groups)
            TileShelve(
              title: label,
              color: Colors.grey,
              entries: entries,
            ),
        ],
      ],
    );
  }

  AppBar libraryHeader(
    BuildContext context,
    AppConfigModel appConfig,
    LibraryView libraryView,
    LibraryFilter filter,
  ) {
    return AppBar(
      leading: badges.Badge(
        badgeContent: Text(
          '${libraryView.length}',
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
                onChanged: (selected) => appConfig.fetchRemote.value = selected,
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.black.withOpacity(0.6),
      elevation: 0.0,
    );
  }
}

// class GameLibraryPage extends StatefulWidget {
//   const GameLibraryPage({Key? key, required this.filter}) : super(key: key);

//   final LibraryFilter filter;

//   @override
//   State<GameLibraryPage> createState() => _GameLibraryPageState();
// }

// class _GameLibraryPageState extends State<GameLibraryPage> {
//   @override
//   Widget build(BuildContext context) {
//     final libraryView =
//         context.watch<LibraryEntriesModel>().filter(widget.filter);

//     final appConfig = context.watch<AppConfigModel>();

//     if (!fetched && appConfig.fetchRemote.value) {
//       RemoteLibraryModel.fromFilter(
//         widget.filter,
//         includeExpansions: appConfig.showExpansions.value,
//       ).then((value) => setState(() {
//             _remoteGames = value;
//             fetched = true;
//           }));
//     }

//     // TODO: Needs to move inside the filter / LibraryView.
//     // final Set<int> entryIds = Set.from(libraryView.all.map((e) => e.id));
//     // if (appConfig.fetchRemote.value) {
//     //   entries.addAll(_remoteGames.where((e) => !entryIds.contains(e.id)));
//     // }

//     return LibraryContent(libraryView: libraryView, filter: widget.filter);
//   }

//   bool fetched = false;
//   List<LibraryEntry> _remoteGames = [];
// }
