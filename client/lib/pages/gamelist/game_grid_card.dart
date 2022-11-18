import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameGridCard extends StatelessWidget {
  GameGridCard({
    Key? key,
    required this.libraryEntry,
  }) : super(key: key);

  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    final appConfig = context.watch<AppConfigModel>();

    return GestureDetector(
      onTap: () =>
          context.pushNamed('details', params: {'gid': '${libraryEntry.id}'}),
      onSecondaryTap: () =>
          EditEntryDialog.show(context, libraryEntry, gameId: libraryEntry.id),
      onLongPress: () => isMobile
          ? context.pushNamed('edit', params: {'gid': '${libraryEntry.id}'})
          : EditEntryDialog.show(
              context,
              libraryEntry,
              gameId: libraryEntry.id,
            ),
      child: GridTile(
        footer: Material(
          color: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: appConfig.cardDecoration == CardDecoration.TAGS
              ? TagsTileBar(libraryEntry)
              : appConfig.cardDecoration == CardDecoration.INFO
                  ? InfoTileBar(libraryEntry)
                  : null,
        ),
        child: Material(
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          clipBehavior: Clip.antiAlias,
          child: libraryEntry.cover != null && libraryEntry.cover!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl:
                      '${Urls.imageProvider}/t_cover_big/${libraryEntry.cover}.jpg',
                  errorWidget: (context, url, error) => Icon(Icons.error),
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
