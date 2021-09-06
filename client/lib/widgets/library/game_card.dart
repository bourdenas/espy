import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/config_model.dart';
import 'package:espy/widgets/details/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameCard extends StatelessWidget {
  GameCard({
    Key? key,
    required this.entry,
  }) : super(key: key);

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfig>();

    return GridTile(
      footer: Material(
        color: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: appConfig.tagsTitleBar ? TagsTileBar(entry) : InfoTileBar(entry),
      ),
      child: Material(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        clipBehavior: Clip.antiAlias,
        child: Hero(
          tag: '${entry.id}_cover',
          child: entry.cover != null && entry.cover!.isNotEmpty
              ? Image.network(
                  '${Urls.imageProvider}/t_cover_big/${entry.cover}.jpg',
                  fit: BoxFit.fitHeight,
                )
              : Image.asset('assets/images/placeholder.png'),
        ),
      ),
    );
  }
}

class InfoTileBar extends StatelessWidget {
  const InfoTileBar(this.entry, {Key? key}) : super(key: key);

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    return GridTileBar(
      backgroundColor: Colors.black45,
      title: GameTitleText(entry.name),
      subtitle: Row(children: [
        if (entry.releaseDate > 0)
          GameTitleText(
              '${DateTime.fromMillisecondsSinceEpoch(entry.releaseDate * 1000).year}'),
        Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
        GameTitleText(entry.storeEntries.map((e) => e.storefront).join(', ')),
      ]),
    );
  }
}

class TagsTileBar extends StatelessWidget {
  const TagsTileBar(this.entry, {Key? key}) : super(key: key);

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    return GridTileBar(
      backgroundColor: Colors.black45,
      title: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final tag in entry.userData.tags)
            Padding(
              padding: const EdgeInsets.all(2),
              child: TagChip(tag: tag),
            ),
        ],
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
