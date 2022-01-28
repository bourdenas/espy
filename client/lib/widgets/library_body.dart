import 'package:espy/constants/urls.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/modules/models/unmatched_library_model.dart';
import 'package:espy/widgets/empty_library.dart';
import 'package:espy/widgets/library_headline.dart';
import 'package:espy/widgets/slates/library_slate.dart';
import 'package:espy/widgets/slates/slate_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class LibraryBody extends StatelessWidget {
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
    final entries = context.watch<GameEntriesModel>().getEntries(null);

    final gogGames = context
        .watch<GameEntriesModel>()
        .getEntries(LibraryFilter(stores: {'gog'}))
        .take(8)
        .map((e) => SlateTileData(
            image: '${Urls.imageProvider}/t_cover_big/${e.cover}.jpg'))
        .toList();

    final steamGames = context
        .watch<GameEntriesModel>()
        .getEntries(LibraryFilter(stores: {'steam'}))
        .take(8)
        .map((e) => SlateTileData(
            image: '${Urls.imageProvider}/t_cover_big/${e.cover}.jpg'))
        .toList();

    final egsGames = context
        .watch<GameEntriesModel>()
        .getEntries(LibraryFilter(stores: {'egs'}))
        .take(8)
        .map((e) => SlateTileData(
            image: '${Urls.imageProvider}/t_cover_big/${e.cover}.jpg'))
        .toList();

    final unmatchedEntries = context.watch<UnmatchedEntriesModel>().entries;

    return SingleChildScrollView(
      key: Key('libraryScrollView'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entries.isNotEmpty) LibraryHeadline() else SizedBox(height: 64),
          if (gogGames.isNotEmpty)
            LibrarySlate(
              text: 'GOG',
              onExpand: () => Navigator.pushNamed(context, 'gog'),
              tiles: gogGames,
            ),
          if (steamGames.isNotEmpty)
            LibrarySlate(
              text: 'Steam',
              onExpand: () => Navigator.pushNamed(context, 'steam'),
              tiles: steamGames,
            ),
          if (egsGames.isNotEmpty)
            LibrarySlate(
              text: 'Epic Game Store',
              onExpand: () => Navigator.pushNamed(context, 'egs'),
              tiles: egsGames,
            ),
          if (unmatchedEntries.isNotEmpty)
            LibrarySlate(
              text: 'Unmatched Entries',
              onExpand: () => Navigator.pushNamed(context, 'unmatched'),
              tiles: unmatchedEntries
                  .take(8)
                  .map((e) => SlateTileData(title: e.title, image: e.image))
                  .toList(),
            ),
          SizedBox(height: 30.0),
        ],
      ),
    );
  }
}
