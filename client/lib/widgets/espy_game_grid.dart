import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/widgets/game_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EspyGameGrid extends StatelessWidget {
  const EspyGameGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      restorationId: 'grid_view_game_entries_grid_offset',
      maxCrossAxisExtent: 300,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.all(16),
      childAspectRatio: .75,
      children: context
          .watch<GameLibraryModel>()
          .games
          .map((entry) => InkResponse(
              enableFeedback: true,
              onTap: () => context.read<GameDetailsModel>().open(entry),
              child: GameCard(
                game: entry.game,
              )))
          .toList(),
    );
  }
}
