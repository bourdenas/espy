import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/pages/library/library_entries_view.dart';
import 'package:espy/pages/library/library_stats.dart';
import 'package:espy/widgets/filters/categories_sliding_chip.dart';
import 'package:espy/widgets/filters/refinements.dart';
import 'package:espy/widgets/gametags/game_chips_filter_bar.dart';
import 'package:espy/widgets/shelve.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key, this.entries});

  final Iterable<LibraryEntry>? entries;

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigModel>();
    final filter = context.watch<LibraryFilterModel>().filter;
    final libraryViewModel = entries == null
        ? context.watch<LibraryViewModel>()
        : LibraryViewModel.custom(appConfig, entries!, filter);

    return Scaffold(
      appBar:
          libraryAppBar(context, appConfig, libraryViewModel.length, filter),
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
          title: 'Library Stats',
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
    BuildContext context,
    AppConfigModel appConfig,
    int libraryViewLength,
    LibraryFilter filter,
  ) {
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
            const GameCategoriesSlidingChip(),
            const SizedBox(width: 8.0),
            const Refinements(),
            const SizedBox(width: 8.0),
            if (context.watch<UserModel>().isSignedIn &&
                entries == null &&
                filter.isNotEmpty)
              CategoryFilterChip('External', appConfig.showExternal),
            const SizedBox(width: 8),
            GameChipsFilterBar(filter),
          ],
        ),
      ),
      backgroundColor: Colors.black.withOpacity(0.6),
      elevation: 0.0,
    );
  }
}
