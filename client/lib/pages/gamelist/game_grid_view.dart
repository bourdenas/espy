import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/pages/gamelist/game_grid_card.dart';
import 'package:flutter/material.dart';

class GameGridView extends StatelessWidget {
  const GameGridView({
    Key? key,
    required this.entries,
  }) : super(key: key);

  final List<LibraryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: GridView.extent(
        primary: true,
        restorationId: 'grid_view_game_entries_grid_offset',
        maxCrossAxisExtent: _maxCardWidth,
        childAspectRatio: _cardAspectRation,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children:
            entries.map((entry) => GameGridCard(libraryEntry: entry)).toList(),
      ),
    );
  }

  static const _maxCardWidth = 300.0;
  static const _cardAspectRation = .75;
}
