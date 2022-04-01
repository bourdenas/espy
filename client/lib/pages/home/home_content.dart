import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/modules/models/unmatched_library_model.dart';
import 'package:espy/pages/home/home_slate.dart';
import 'package:espy/pages/home/slate_tile.dart';
import 'package:espy/widgets/empty_library.dart';
import 'package:espy/pages/home/home_headline.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = context.watch<GameEntriesModel>().getEntries(null);
    final unmatchedEntries = context.watch<UnmatchedEntriesModel>().entries;

    return Scaffold(
      body: entries.isNotEmpty || unmatchedEntries.isNotEmpty
          ? library(context)
          : EmptyLibrary(),
    );
  }

  Widget library(BuildContext context) {
    final slates = context.watch<HomeSlatesModel>().slates;
    final unmatchedEntries = context.watch<UnmatchedEntriesModel>().entries;

    return ListView(
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (AppConfigModel.isMobile(context))
          HomeHeadline()
        else
          SizedBox(height: 64),
        for (final slate in slates)
          if (slate.entries.isNotEmpty)
            HomeSlate(
              title: slate.title,
              onExpand: () => Navigator.pushNamed(context, '/games',
                  arguments: slate.filter.encode()),
              tiles: slate.entries
                  .map((libraryEntry) => SlateTileData(
                        image:
                            '${Urls.imageProvider}/t_cover_big/${libraryEntry.cover}.jpg',
                        onTap: () => Navigator.pushNamed(context, '/details',
                            arguments: '${libraryEntry.id}'),
                      ))
                  .toList(),
            ),
        if (slates.isEmpty && unmatchedEntries.isNotEmpty)
          HomeSlate(
            title: 'Unmatched Entries',
            onExpand: () => Navigator.pushNamed(context, '/unmatched'),
            tiles: unmatchedEntries
                .take(AppConfigModel.isMobile(context) ? 8 : 32)
                .map((entry) => SlateTileData(
                      title: entry.title,
                      image: null,
                      onTap: () => MatchingDialog.show(context, entry),
                    ))
                .toList(),
          ),
        SizedBox(height: 30.0),
      ],
    );
  }
}
