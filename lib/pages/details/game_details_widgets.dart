import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class GameEntryActionBar extends StatelessWidget {
  const GameEntryActionBar(
    this.gameEntry,
    this.libraryEntry, {
    Key? key,
  }) : super(key: key);

  final LibraryEntry libraryEntry;
  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            releaseYear(),
            SizedBox(width: 8.0),
            rating(),
            SizedBox(width: 16.0),
            actionButtons(context),
            SizedBox(width: 16.0),
            linkButtons(context, gameEntry, libraryEntry),
          ],
        ),
      ],
    );
  }

  Widget releaseYear() {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 2.0,
        horizontal: 8.0,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        '${DateTime.fromMillisecondsSinceEpoch(gameEntry.releaseDate * 1000).year}',
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget rating() {
    return Row(
      children: [
        Icon(
          Icons.star,
          color: Colors.amber,
          size: 18.0,
        ),
        SizedBox(width: 4.0),
        Text(gameEntry.igdbRating > 0
            ? (5 * gameEntry.igdbRating / 100.0).toStringAsFixed(1)
            : '--'),
      ],
    );
  }

  Widget actionButtons(BuildContext context) {
    final inWishlist = context.watch<WishlistModel>().contains(gameEntry.id);

    return Row(
      children: [
        IconButton(
          onPressed: () => AppConfigModel.isMobile(context)
              ? context.pushNamed('edit', params: {'gid': '${gameEntry.id}'})
              : EditEntryDialog.show(
                  context,
                  libraryEntry,
                  gameEntry: gameEntry,
                ),
          icon: Icon(
            Icons.edit,
            size: 24.0,
          ),
          splashRadius: 20.0,
        ),
        if (libraryEntry.storeEntries.isEmpty)
          IconButton(
            onPressed: () {
              if (inWishlist) {
                context
                    .read<WishlistModel>()
                    .remove_from_wishlist(gameEntry.id);
              } else {
                context.read<WishlistModel>().add_to_wishlist(libraryEntry);
              }
            },
            icon: Icon(
              inWishlist ? Icons.favorite : Icons.favorite_border_outlined,
              color: Colors.red,
              size: 24.0,
            ),
            splashRadius: 20.0,
          ),
      ],
    );
  }

  Widget linkButtons(
      BuildContext context, GameEntry gameEntry, LibraryEntry libraryEntry) {
    return Row(
      children: [
        for (final label in const [
          'Official',
          'Igdb',
          'Wikipedia',
        ])
          for (final website
              in gameEntry.websites.where((site) => site.authority == label))
            IconButton(
              onPressed: () async => await launchUrl(Uri.parse(website.url)),
              icon: websiteIcon(website.authority),
              splashRadius: 20.0,
            ),
        for (final label in const ['Gog', 'Steam', 'Egs'])
          for (final website
              in gameEntry.websites.where((site) => site.authority == label))
            IconButton(
              onPressed: () async => await launchUrl(Uri.parse(website.url)),
              icon: websiteIcon(website.authority,
                  disabled: libraryEntry.storeEntries.every(
                      (entry) => entry.storefront != label.toLowerCase())),
              splashRadius: 20.0,
            ),
      ],
    );
  }

  Widget websiteIcon(String website, {bool disabled = false}) {
    switch (website) {
      case "Official":
        return Icon(Icons.web);
      case "Wikipedia":
        return Image.asset('assets/images/wikipedia-128.png');
      case "Igdb":
        return Image.asset('assets/images/igdb-128.png');
      case "Gog":
        return Image.asset(
          'assets/images/gog-128.png',
          color: disabled ? Colors.grey[800]!.withOpacity(.8) : Colors.white,
          colorBlendMode: BlendMode.modulate,
        );
      case "Steam":
        return Image.asset(
          'assets/images/steam-128.png',
          color: disabled ? Colors.grey[800]!.withOpacity(.8) : Colors.white,
          colorBlendMode: BlendMode.modulate,
        );
      case "Egs":
        return Image.asset(
          'assets/images/egs-128.png',
          color: disabled ? Colors.grey[800]!.withOpacity(.8) : Colors.white,
          colorBlendMode: BlendMode.modulate,
        );
      case "Youtube":
        return Image.asset('assets/images/youtube-128.png');
    }
    return Icon(Icons.error);
  }
}

class RelatedGamesGroup extends StatelessWidget {
  const RelatedGamesGroup(this.title, this.gameDigests, {Key? key})
      : super(key: key);

  final String title;
  final List<GameDigest> gameDigests;

  @override
  Widget build(BuildContext context) {
    return TileShelve(
      title: title,
      entries: gameDigests
          .map((gameEntry) => LibraryEntry.fromGameDigest(gameEntry)),
    );
  }
}
