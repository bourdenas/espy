import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/library_filter.dart';
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
    final entries = context.watch<GameEntriesModel>().getEntries(null);

    final gogGames = context
        .watch<GameEntriesModel>()
        .getEntries(LibraryFilter(stores: {'gog'}))
        .take(8)
        .map((e) => SlateTileData(
            id: '${e.id}',
            image: '${Urls.imageProvider}/t_cover_big/${e.cover}.jpg'))
        .toList();

    final steamGames = context
        .watch<GameEntriesModel>()
        .getEntries(LibraryFilter(stores: {'steam'}))
        .take(8)
        .map((e) => SlateTileData(
            id: '${e.id}',
            image: '${Urls.imageProvider}/t_cover_big/${e.cover}.jpg'))
        .toList();

    final egsGames = context
        .watch<GameEntriesModel>()
        .getEntries(LibraryFilter(stores: {'egs'}))
        .take(8)
        .map((e) => SlateTileData(
            id: '${e.id}',
            image: '${Urls.imageProvider}/t_cover_big/${e.cover}.jpg'))
        .toList();

    final unmatchedEntries = context.watch<UnmatchedEntriesModel>().entries;

    return SingleChildScrollView(
      key: Key('libraryScrollView'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entries.isNotEmpty) HomeHeadline() else SizedBox(height: 64),
          if (gogGames.isNotEmpty)
            HomeSlate(
              text: 'GOG',
              onExpand: () => Navigator.pushNamed(context, '/games',
                  arguments: LibraryFilter(stores: {'gog'}).encode()),
              tiles: gogGames,
            ),
          if (steamGames.isNotEmpty)
            HomeSlate(
              text: 'Steam',
              onExpand: () => Navigator.pushNamed(context, '/games',
                  arguments: LibraryFilter(stores: {'steam'}).encode()),
              tiles: steamGames,
            ),
          if (egsGames.isNotEmpty)
            HomeSlate(
              text: 'Epic Game Store',
              onExpand: () => Navigator.pushNamed(context, '/games',
                  arguments: LibraryFilter(stores: {'egs'}).encode()),
              tiles: egsGames,
            ),
          HomeSlate(
            text: 'Larian',
            onExpand: () => Navigator.pushNamed(context, '/games',
                arguments: LibraryFilter(
                    companies: {Annotation(name: 'Larian', id: 510)}).encode()),
            tiles: context
                .watch<GameEntriesModel>()
                .getEntries(LibraryFilter(
                    companies: {Annotation(name: 'Larian', id: 510)}))
                .take(8)
                .map((e) => SlateTileData(
                    id: '${e.id}',
                    image: '${Urls.imageProvider}/t_cover_big/${e.cover}.jpg'))
                .toList(),
          ),
          if (unmatchedEntries.isNotEmpty)
            HomeSlate(
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
