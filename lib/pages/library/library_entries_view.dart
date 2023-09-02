import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/gamelist/game_grid_card.dart';
import 'package:espy/pages/gamelist/game_list_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryEntriesView extends StatelessWidget {
  const LibraryEntriesView({
    Key? key,
    required this.entries,
    this.cardWidth,
    this.cardAspectRatio,
    this.pushNavigation = true,
  }) : super(key: key);

  final Iterable<LibraryEntry> entries;
  final double? cardWidth;
  final double? cardAspectRatio;

  // If true clicks on an tile will result to a push event in routing.
  // Otherwise, it will replace current page.
  final bool pushNavigation;

  @override
  Widget build(BuildContext context) {
    return context.watch<AppConfigModel>().libraryLayout.value ==
            LibraryLayout.grid
        ? gridView(entries)
        : listView(entries);
  }

  SliverGrid gridView(Iterable<LibraryEntry> matchedEntries) {
    return SliverGrid.extent(
      maxCrossAxisExtent: cardWidth ?? 200,
      childAspectRatio: cardAspectRatio ?? .75,
      children: matchedEntries
          .map((e) => GameGridCard(
                entry: e,
                pushNavigation: pushNavigation,
              ))
          .toList(),
    );
  }

  SliverGrid listView(Iterable<LibraryEntry> matchedEntries) {
    return SliverGrid.extent(
      maxCrossAxisExtent: cardWidth ?? 600.0,
      childAspectRatio: cardAspectRatio ?? 2.5,
      children:
          matchedEntries.map((e) => GameListCard(libraryEntry: e)).toList(),
    );
  }
}
