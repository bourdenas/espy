import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/library/filter_chips.dart';
import 'package:espy/widgets/library/game_card.dart';
import 'package:espy/widgets/library/tags_context_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryGridView extends StatefulWidget {
  static const maxCardWidth = 300;
  static const cardAspectRation = .75;
  static const maxCardHeight = maxCardWidth / cardAspectRation;

  @override
  _LibraryGridViewState createState() => _LibraryGridViewState();
}

class _LibraryGridViewState extends State<LibraryGridView> {
  int _cardsPerRow = 0;
  int _visibleRows = 0;

  void _updateColRow(BuildContext context) {
    _cardsPerRow = (context.size!.width / LibraryGridView.maxCardWidth).ceil();

    final cardWidth = (context.size!.width / _cardsPerRow).floor();
    _visibleRows =
        (context.size!.height / (cardWidth / LibraryGridView.cardAspectRation))
            .ceil();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _updateColRow(context);
      context
          .read<GameLibraryModel>()
          .fetch(limit: _cardsPerRow * (_visibleRows + 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final games = context.watch<GameEntriesModel>().games;

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        _updateColRow(context);
        if (_cardsPerRow * _visibleRows > games.length) {
          context
              .read<GameLibraryModel>()
              .fetch(limit: _cardsPerRow * _visibleRows);
        }

        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: Column(
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
                      2 * LibraryGridView.maxCardHeight) {
                    context
                        .read<GameLibraryModel>()
                        .fetch(limit: _cardsPerRow * _visibleRows);
                  }
                  return true;
                },
                child: Scrollbar(
                  child: GridView.extent(
                    restorationId: 'grid_view_game_entries_grid_offset',
                    maxCrossAxisExtent: LibraryGridView.maxCardWidth as double,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    childAspectRatio: LibraryGridView.cardAspectRation,
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
                                  await showTagsContextMenu(
                                      context, event, entry),
                            )))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
