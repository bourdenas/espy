import 'package:animate_do/animate_do.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/pages/gamelist/game_list_card.dart';
import 'package:flutter/material.dart';

class GameListView extends StatelessWidget {
  const GameListView({
    Key? key,
    required this.entries,
  }) : super(key: key);

  final List<LibraryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FadeInUp(
        from: 20,
        duration: Duration(milliseconds: 500),
        child: CustomScrollView(
          primary: true,
          shrinkWrap: true,
          slivers: [
            SliverGrid.extent(
              maxCrossAxisExtent: _maxCardWidth,
              childAspectRatio: _cardAspectRation,
              children: entries.map((e) => GameListCard(entry: e)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  static const _maxCardWidth = 600.0;
  static const _cardAspectRation = 2.5;
}
