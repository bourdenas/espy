import 'package:espy/constants/urls.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/proto/library.pb.dart';
import 'package:espy/widgets/library/tags_context_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryGridView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final games = context.watch<GameEntriesModel>().games;

    if (games.isEmpty) return EmptyLibrary();

    return Scrollbar(
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
                  .showGameDetails('${entry.game.id}'),
              child: Listener(
                child: GameCard(
                  entry: entry,
                ),
                onPointerDown: (PointerDownEvent event) async =>
                    await showTagsContextMenu(context, event, entry),
              )))
          .toList(),
    ));
  }
}

class EmptyLibrary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircleAvatar(
            radius: 64,
            child: Image.asset('assets/images/gog-128.png'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircleAvatar(
            radius: 64,
            child: Image.asset('assets/images/steam-128.png'),
          ),
        ),
      ],
    );
  }
}

class GameCard extends StatelessWidget {
  GameCard({
    Key? key,
    required this.entry,
  }) : super(key: key);

  final GameEntry entry;

  @override
  Widget build(BuildContext context) {
    return GridTile(
      footer: Material(
        color: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: GridTileBar(
          backgroundColor: Colors.black45,
          title: GameTitleText(entry.game.name),
          subtitle: Row(children: [
            GameTitleText(
                '${DateTime.fromMillisecondsSinceEpoch(entry.game.firstReleaseDate.seconds.toInt() * 1000).year}'),
            Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
            GameTitleText(entry.storeEntry.map((e) => e.store).join(', ')),
          ]),
        ),
      ),
      child: Material(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        clipBehavior: Clip.antiAlias,
        child: Hero(
          tag: '${entry.game.id}_cover',
          child: entry.game.cover.imageId.isNotEmpty
              ? Image.network(
                  '${Urls.imageProvider}/t_cover_big/${entry.game.cover.imageId}.jpg',
                  fit: BoxFit.fitHeight,
                )
              : Image.asset('assets/images/placeholder.png'),
        ),
      ),
    );
  }
}

class GameTitleText extends StatelessWidget {
  const GameTitleText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(text),
    );
  }
}
