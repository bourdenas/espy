import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/pages/library/library_entries_view.dart';
import 'package:espy/pages/library/library_stats.dart';
import 'package:espy/widgets/filters/categories_sliding_chip.dart';
import 'package:espy/widgets/shelve.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigModel>();
    final libraryViewModel = context.watch<LibraryViewModel>();

    return Scaffold(
      appBar: libraryAppBar(context, appConfig, libraryViewModel.length),
      body: libraryBody(appConfig, libraryViewModel),
    );
  }

  CustomScrollView libraryBody(
      AppConfigModel appConfig, LibraryViewModel libraryViewModel) {
    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        Shelve(
          title: 'Drill-down',
          expansion: LibraryStats(libraryViewModel.entries),
          color: Colors.amber,
          expanded: true,
        ),
        if (appConfig.libraryGrouping.value == LibraryGrouping.none)
          LibraryEntriesView(
            entries: libraryViewModel.entries,
          )
        else ...[
          for (final (label, entries) in libraryViewModel.groups)
            TileShelve(
              title: '$label (${entries.length})',
              color: Colors.grey,
              entries: entries,
            ),
        ],
      ],
    );
  }

  AppBar libraryAppBar(
      BuildContext context, AppConfigModel appConfig, int libraryViewLength) {
    return AppBar(
      leading: badges.Badge(
        badgeContent: Text(
          '$libraryViewLength',
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
      title: SizedBox(
        height: 48,
        child: ListView(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          children: [
            const CategoriesSlidingChip(),
            // const SizedBox(width: 8.0),
            // const KeywordsSlidingChip(),
            // const SizedBox(width: 8.0),
            // EspyChipsFilterBar(filter),
          ],
        ),
      ),
      backgroundColor: Colors.black.withOpacity(0.6),
      elevation: 0.0,
    );
  }
}
