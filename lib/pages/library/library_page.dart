import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/pages/library/library_entries_view.dart';
import 'package:espy/widgets/gametags/game_chips_filter_bar.dart';
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
      title: SizedBox(
        height: 48,
        child: ListView(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          children: [
            GameChipsFilterBar(filter),
            const SizedBox(width: 8),
            if (context.watch<UserModel>().isSignedIn)
              Row(
                children: [
                  LibraryChoice('Main Games', appConfig.showMains),
                  const SizedBox(width: 8),
                  LibraryChoice('Expansions', appConfig.showExpansions),
                  const SizedBox(width: 8),
                  LibraryChoice('DLCs', appConfig.showDlcs),
                  const SizedBox(width: 8),
                  LibraryChoice('Versions', appConfig.showVersions),
                  const SizedBox(width: 8),
                  LibraryChoice('Bundles', appConfig.showBundles),
                  const SizedBox(width: 8),
                  LibraryChoice('External', appConfig.showExternal),
                ],
              ),
          ],
        ),
      ),
      backgroundColor: Colors.black.withOpacity(0.6),
      elevation: 0.0,
    );
  }
}

class LibraryChoice extends StatelessWidget {
  const LibraryChoice(
    this.label,
    this.option, {
    super.key,
  });

  final String label;
  final BoolOption option;

  @override
  Widget build(BuildContext context) {
    final appConfig = context.read<AppConfigModel>();
    return GestureDetector(
      onSecondaryTap: () {
        appConfig.showMains.value = false;
        appConfig.showExpansions.value = false;
        appConfig.showDlcs.value = false;
        appConfig.showVersions.value = false;
        appConfig.showBundles.value = false;
        option.value = true;
      },
      child: ChoiceChip(
        label: Text(label),
        selected: option.value,
        onSelected: (selected) => option.value = selected,
      ),
    );
  }
}
