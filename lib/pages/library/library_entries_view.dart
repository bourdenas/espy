import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/library/library_grid_card.dart';
import 'package:espy/pages/library/library_list_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryEntriesView extends StatelessWidget {
  const LibraryEntriesView({
    super.key,
    required this.entries,
    this.pushNavigation = true,
  });

  final Iterable<LibraryEntry> entries;

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
      maxCrossAxisExtent: AppConfigModel.gridCardContraints.maxCardWidth,
      childAspectRatio: AppConfigModel.gridCardContraints.cardAspectRatio,
      children: matchedEntries
          .map((libraryEntry) => LibraryGridCard(
                libraryEntry,
                pushNavigation: pushNavigation,
              ))
          .toList(),
    );
  }

  SliverGrid listView(Iterable<LibraryEntry> matchedEntries) {
    return SliverGrid.extent(
      maxCrossAxisExtent: AppConfigModel.listCardContraints.maxCardWidth,
      childAspectRatio: AppConfigModel.listCardContraints.cardAspectRatio,
      children:
          matchedEntries.map((e) => LibraryListCard(libraryEntry: e)).toList(),
    );
  }
}
