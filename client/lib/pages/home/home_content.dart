import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/modules/models/failed_entries_model.dart';
import 'package:espy/pages/home/home_slate.dart';
import 'package:espy/pages/home/slate_tile.dart';
import 'package:espy/widgets/empty_library.dart';
import 'package:espy/pages/home/home_headline.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/src/provider.dart';

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = context.watch<GameEntriesModel>().getEntries(null);
    final unmatchedEntries = context.watch<UnmatchedEntriesModel>().entries;

    return entries.isNotEmpty || unmatchedEntries.isNotEmpty
        ? library(context)
        : EmptyLibrary();
  }

  Widget library(BuildContext context) {
    final slates = context.watch<HomeSlatesModel>().slates;
    final unmatchedEntries = context.watch<UnmatchedEntriesModel>().entries;
    final isMobile = AppConfigModel.isMobile(context);

    return ListView(
      // crossAxisAlignment: CrossAxisAlignment.start,
      primary: true,
      children: [
        if (isMobile) HomeHeadline() else SizedBox(height: 16),
        for (final slate in slates)
          if (slate.entries.isNotEmpty)
            HomeSlate(
              title: slate.title,
              onExpand: () => context.pushNamed('games',
                  queryParams: slate.filter.params()),
              tiles: slate.entries
                  .map((libraryEntry) => SlateTileData(
                        image:
                            '${Urls.imageProvider}/t_cover_big/${libraryEntry.cover}.jpg',
                        onTap: () => context.pushNamed('details',
                            params: {'gid': '${libraryEntry.id}'}),
                        onLongTap: () => isMobile
                            ? context.pushNamed('edit',
                                params: {'gid': '${libraryEntry.id}'})
                            : EditEntryDialog.show(
                                context,
                                libraryEntry,
                                gameId: libraryEntry.id,
                              ),
                      ))
                  .toList(),
            ),
        if (slates.isEmpty && unmatchedEntries.isNotEmpty)
          HomeSlate(
            title: 'Unmatched Entries',
            onExpand: () => context.pushNamed('unmatched'),
            tiles: unmatchedEntries
                .take(isMobile ? 8 : 32)
                .map((entry) => SlateTileData(
                      title: entry.title,
                      image: null,
                      onTap: () => MatchingDialog.show(
                        context,
                        storeEntry: entry,
                        onMatch: (storeEntry, gameEntry) => context
                            .read<GameLibraryModel>()
                            .matchEntry(storeEntry, gameEntry),
                      ),
                    ))
                .toList(),
          ),
        SizedBox(height: 30.0),
      ],
    );
  }
}
