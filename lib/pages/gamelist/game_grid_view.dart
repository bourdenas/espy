import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/gamelist/library_entries_view.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';

class GameGridView extends StatelessWidget {
  const GameGridView(
    this.libraryView, {
    Key? key,
  }) : super(key: key);

  final LibraryView libraryView;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        if (!libraryView.hasGroups)
          LibraryEntriesView(
            entries: libraryView.all,
            cardWidth: _maxCardWidth,
            cardAspectRatio: _cardAspectRation,
          )
        else ...[
          for (final (label, entries) in libraryView.groups)
            TileShelve(
              title: label,
              color: Colors.grey,
              entries: entries,
              cardWidth: _maxCardWidth,
              cardAspectRatio: _cardAspectRation,
            ),
        ],
      ],
    );
  }

  static const _maxCardWidth = 250.0;
  static const _cardAspectRation = .75;
}
