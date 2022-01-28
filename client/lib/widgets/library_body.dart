import 'package:espy/modules/models/game_entries_model.dart';
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
    final unmatchedEntries = context.watch<UnmatchedEntriesModel>().entries;
    print(unmatchedEntries.length);

    return SingleChildScrollView(
      key: Key('libraryScrollView'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LibraryHeadline(),
          LibrarySlate(
            text: 'GOG',
            onExpand: () => Navigator.pushNamed(context, 'gog'),
            tiles: [],
          ),
          // LibrarySlate(
          //   text: 'Steam',
          //   onExpand: () => Navigator.pushNamed(context, 'steam'),
          //   tiles: [],
          // ),
          // LibrarySlate(
          //   text: 'Epic',
          //   onExpand: () => Navigator.pushNamed(context, 'epic'),
          //   tiles: [],
          // ),
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
