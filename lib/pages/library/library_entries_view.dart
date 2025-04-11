import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/library/library_grid_card.dart';
import 'package:espy/pages/library/library_list_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryEntriesView extends StatelessWidget {
  const LibraryEntriesView({
    super.key,
    required this.entries,
    this.pushNavigation = true,
    this.grayOutMissing = false,
  });

  final Iterable<LibraryEntry> entries;

  // If true clicks on an tile will result to a push event in routing.
  // Otherwise, it will replace current page.
  final bool pushNavigation;

  // If true titles shown on the view that are not in user's library are grayed
  // out.
  final bool grayOutMissing;

  @override
  Widget build(BuildContext context) {
    final shownEntries =
        context.watch<FilterModel>().processLibraryEntries(entries);

    return context.watch<AppConfigModel>().libraryLayout.value ==
            LibraryLayout.grid
        ? gridView(shownEntries)
        : listView(shownEntries);
  }

  SliverGrid gridView(Iterable<LibraryEntry> matchedEntries) {
    return SliverGrid.extent(
      maxCrossAxisExtent: AppConfigModel.gridCardContraints.maxCardWidth,
      childAspectRatio: AppConfigModel.gridCardContraints.cardAspectRatio,
      children: matchedEntries
          .map((libraryEntry) =>
              LibraryGridCard(libraryEntry, grayOutMissing: grayOutMissing))
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
