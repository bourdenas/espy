import 'package:espy/proto/igdbapi.pb.dart';
import 'package:flutter/material.dart';

class GameCard extends StatelessWidget {
  GameCard({
    Key? key,
    required this.game,
  }) : super(key: key);

  final Game game;

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
          title: GameTitleText(game.name),
          subtitle: GameTitleText("Steam"),
        ),
      ),
      child: Material(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        clipBehavior: Clip.antiAlias,
        child: Hero(
          tag: '${game.id}_cover',
          child: game.cover.imageId.isNotEmpty
              ? Image.network(
                  'https://images.igdb.com/igdb/image/upload/t_cover_big/${game.cover.imageId}.jpg',
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
