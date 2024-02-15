import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/pages/library/library_entries_view.dart';
import 'package:espy/widgets/gametags/game_chips_filter_bar.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigModel>();
    final filter = context.watch<LibraryFilterModel>().filter;
    final libraryViewModel = context.watch<LibraryViewModel>();

    return Scaffold(
      appBar:
          libraryHeader(context, appConfig, libraryViewModel.length, filter),
      body: libraryBody(appConfig, libraryViewModel),
    );
  }

  CustomScrollView libraryBody(
      AppConfigModel appConfig, LibraryViewModel libraryViewModel) {
    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
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

  AppBar libraryHeader(
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
                value: appConfig.showOutOfLib.value,
                onChanged: (selected) =>
                    appConfig.showOutOfLib.value = selected,
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
