import 'package:espy/proto/library.pb.dart';
import 'package:espy/widgets/game_card.dart';
import 'package:flutter/material.dart';

class EspyGameGrid extends StatelessWidget {
  const EspyGameGrid(this.gameEntries);

  final List<GameEntry> gameEntries;

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      restorationId: 'grid_view_game_entries_grid_offset',
      maxCrossAxisExtent: 300,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.all(16),
      childAspectRatio: .75,
      children: gameEntries
          .map((entry) => GameCard(
                game: entry.game,
              ))
          .toList(),
    );
  }
}
