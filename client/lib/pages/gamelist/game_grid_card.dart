import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameGridCard extends StatelessWidget {
  GameGridCard({
    Key? key,
    required this.entry,
  }) : super(key: key);

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigModel>();

    return GestureDetector(
      onTap: () => context.pushNamed('details', params: {'gid': '${entry.id}'}),
      onSecondaryTap: () => EditEntryDialog.show(context, entry),
      onLongPress: () => EditEntryDialog.show(context, entry),
      child: GridTile(
        footer: Material(
          color: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: appConfig.cardDecoration == CardDecoration.TAGS
              ? TagsTileBar(entry)
              : appConfig.cardDecoration == CardDecoration.INFO
                  ? InfoTileBar(entry)
                  : null,
        ),
        child: Material(
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          clipBehavior: Clip.antiAlias,
          child: Hero(
            tag: '${entry.id}_cover',
            child: entry.cover != null && entry.cover!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl:
                        '${Urls.imageProvider}/t_cover_big/${entry.cover}.jpg',
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    fit: BoxFit.fitHeight,
                  )
                : Image.asset('assets/images/placeholder.png'),
          ),
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
      title: GameCardChips(entry),
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