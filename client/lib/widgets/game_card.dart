import 'package:espy/constants/urls.dart';
import 'package:espy/proto/library.pb.dart' show GameEntry;
import 'package:flutter/material.dart';

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
          subtitle: GameTitleText("Steam"),
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
