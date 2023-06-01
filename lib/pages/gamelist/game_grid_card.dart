import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameGridCard extends StatelessWidget {
  const GameGridCard({
    Key? key,
    required this.entry,
    required this.pushNavigation,
  }) : super(key: key);

  final LibraryEntry entry;
  final bool pushNavigation;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    final appConfig = context.watch<AppConfigModel>();

    return GestureDetector(
      onTap: () => pushNavigation
          ? context.pushNamed('details', pathParameters: {'gid': '${entry.id}'})
          : context
              .replaceNamed('details', pathParameters: {'gid': '${entry.id}'}),
      onSecondaryTap: () =>
          EditEntryDialog.show(context, entry, gameId: entry.id),
      onLongPress: () => isMobile
          ? context.pushNamed('edit', pathParameters: {'gid': '${entry.id}'})
          : EditEntryDialog.show(
              context,
              entry,
              gameId: entry.id,
            ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridTile(
          footer: cardFooter(appConfig),
          child: coverImage(context),
        ),
      ),
    );
  }

  Widget coverImage(BuildContext context) {
    return Material(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          entry.cover != null && entry.cover!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl:
                      '${Urls.imageProvider}/t_cover_big/${entry.cover}.jpg',
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  fit: BoxFit.fitHeight,
                )
              : Image.asset('assets/images/placeholder.png'),
          if (entry.storeEntries.isEmpty)
            Positioned(
              right: -8,
              child: SizedBox(
                height: 32,
                child: FloatingActionButton(
                  heroTag: 'add_${entry.id}',
                  mini: true,
                  tooltip: 'Add...',
                  backgroundColor: const Color(0x00FFFFFF),
                  onPressed: () {
                    context.read<WishlistModel>().addToWishlist(entry);
                  },
                  child: const Icon(
                    Icons.add_box,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget cardFooter(AppConfigModel appConfig) {
    return Material(
      color: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: appConfig.cardDecoration.value == CardDecoration.tags
          ? TagsTileBar(entry)
          : appConfig.cardDecoration.value == CardDecoration.info
              ? InfoTileBar(entry)
              : null,
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
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
        if (entry.storeEntries.isNotEmpty)
          GameTitleText(
              entry.storeEntries.map((e) => e.storefront).toSet().join(', ')),
      ]),
    );
  }
}

class TagsTileBar extends StatelessWidget {
  const TagsTileBar(this.libraryEntry, {Key? key}) : super(key: key);

  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
    return GridTileBar(
      backgroundColor: Colors.black45,
      title: GameCardChips(
        libraryEntry: libraryEntry,
      ),
    );
  }
}

class GameTitleText extends StatelessWidget {
  const GameTitleText(this.text, {Key? key}) : super(key: key);

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
