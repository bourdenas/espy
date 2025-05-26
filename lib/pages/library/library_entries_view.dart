import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/library/library_grid_card.dart';
import 'package:espy/pages/library/library_list_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryEntriesView extends StatelessWidget {
  const LibraryEntriesView(
    this.libraryEntries, {
    super.key,
    this.grayOutMissing = false,
  });

  final Iterable<LibraryEntry> libraryEntries;

  // If true titles shown on the view that are not in user's library are grayed
  // out.
  final bool grayOutMissing;

  @override
  Widget build(BuildContext context) {
    return context.watch<AppConfigModel>().libraryLayout.value ==
            LibraryLayout.grid
        ? gridView(libraryEntries)
        : listView(libraryEntries);
  }

  SliverGrid gridView(Iterable<LibraryEntry> libraryEntries) {
    return SliverGrid.extent(
      maxCrossAxisExtent: AppConfigModel.gridCardContraints.maxCardWidth,
      childAspectRatio: AppConfigModel.gridCardContraints.cardAspectRatio,
      children: libraryEntries
          .map((libraryEntry) =>
              LibraryGridCard(libraryEntry, grayOutMissing: grayOutMissing))
          .toList(),
    );
  }

  SliverGrid listView(Iterable<LibraryEntry> libraryEntries) {
    return SliverGrid.extent(
      maxCrossAxisExtent: AppConfigModel.listCardContraints.maxCardWidth,
      childAspectRatio: AppConfigModel.listCardContraints.cardAspectRatio,
      children:
          libraryEntries.map((e) => LibraryListCard(libraryEntry: e)).toList(),
    );
  }
}
