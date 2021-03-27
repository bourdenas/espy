import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/widgets/game_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';

class GameLibrary extends StatelessWidget {
  const GameLibrary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<GameLibraryModel>().filter;
    return Column(children: [
      Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              if (filter.company != null)
                InputChip(
                  label: Text('${filter.company!.name}'),
                  backgroundColor: Colors.red[700],
                  onDeleted: () {
                    context.read<GameLibraryModel>().clearFilter();
                  },
                ),
              if (filter.collection != null)
                InputChip(
                  label: Text('${filter.collection!.name}'),
                  backgroundColor: Colors.indigo[700],
                  onDeleted: () {
                    context.read<GameLibraryModel>().clearFilter();
                  },
                ),
              if (filter.tag != null)
                InputChip(
                  label: Text('${filter.tag}'),
                  onDeleted: () {
                    context.read<GameLibraryModel>().clearFilter();
                  },
                ),
              if (filter.company != null ||
                  filter.collection != null ||
                  filter.tag != null)
                Padding(padding: EdgeInsets.symmetric(horizontal: 16)),
            ],
          )),
      Expanded(
        child: GridView.extent(
          restorationId: 'grid_view_game_entries_grid_offset',
          maxCrossAxisExtent: 300,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          childAspectRatio: .75,
          children: context
              .watch<GameLibraryModel>()
              .games
              .map((entry) => InkResponse(
                  enableFeedback: true,
                  onTap: () => context.read<EspyRouterDelegate>().gameId =
                      '${entry.game.id}',
                  child: GameCard(
                    game: entry.game,
                  )))
              .toList(),
        ),
      ),
    ]);
  }
}
