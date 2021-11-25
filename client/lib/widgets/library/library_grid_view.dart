import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/library/game_card.dart';
import 'package:espy/widgets/library/library_view.dart';
import 'package:espy/widgets/library/tags_context_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryGridView extends LibraryView {
  const LibraryGridView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filter =
        context.select((EspyRouterDelegate delegate) => delegate.filter);
    final games = context.watch<GameEntriesModel>().getEntries(filter);

    return Scrollbar(
      child: GridView.extent(
        restorationId: 'grid_view_game_entries_grid_offset',
        maxCrossAxisExtent: _maxCardWidth,
        childAspectRatio: _cardAspectRation,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }

  @override
  int visibleEntries(BuildContext context) {
    final cardsPerRow = (context.size!.width / _maxCardWidth).ceil();
    final cardWidth = (context.size!.width / cardsPerRow).floor();
    final visibleRows =
        (context.size!.height / (cardWidth / _cardAspectRation)).ceil();

    return cardsPerRow * visibleRows;
  }

  @override
  double get scrollThreshold => 2 * _maxCardHeight;

  static const _maxCardWidth = 300.0;
  static const _cardAspectRation = .75;
  static const _maxCardHeight = _maxCardWidth / _cardAspectRation;
}
