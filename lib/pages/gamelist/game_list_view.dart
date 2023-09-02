import 'package:animate_do/animate_do.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/gamelist/game_list_card.dart';
import 'package:flutter/material.dart';

class GameListView extends StatelessWidget {
  const GameListView(
    this.libraryView, {
    Key? key,
  }) : super(key: key);

  final LibraryView libraryView;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FadeInUp(
        from: 20,
        duration: const Duration(milliseconds: 500),
        child: CustomScrollView(
          primary: true,
          shrinkWrap: true,
          slivers: [
            SliverGrid.extent(
              maxCrossAxisExtent: _maxCardWidth,
              childAspectRatio: _cardAspectRation,
              children: libraryView.all
                  .map((e) => GameListCard(libraryEntry: e))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  static const _maxCardWidth = 600.0;
  static const _cardAspectRation = 2.5;
}
