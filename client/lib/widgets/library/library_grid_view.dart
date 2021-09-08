import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/library/filter_chips.dart';
import 'package:espy/widgets/library/game_card.dart';
import 'package:espy/widgets/library/tags_context_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryGridView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final games = context.watch<GameEntriesModel>().games;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: FilterChips(),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.maxScrollExtent -
                      scrollInfo.metrics.pixels <
                  1000) {
                context.read<GameLibraryModel>().fetch();
              }
              return true;
            },
            child: Scrollbar(
              child: GridView.extent(
                restorationId: 'grid_view_game_entries_grid_offset',
                maxCrossAxisExtent: 300,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                childAspectRatio: .75,
                children: games
                    .map((entry) => InkResponse(
                        enableFeedback: true,
                        onTap: () => context
                            .read<EspyRouterDelegate>()
                            .showGameDetails('${entry.id}'),
                        child: Listener(
                          child: GameCard(
                            entry: entry,
                          ),
                          onPointerDown: (PointerDownEvent event) async =>
                              await showTagsContextMenu(context, event, entry),
                        )))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
