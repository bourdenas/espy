import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:espy/widgets/game_pulse.dart';
import 'package:espy/widgets/release_date_chip.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:espy/widgets/tiles/tile_size.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class GameEntryActionBar extends StatelessWidget {
  const GameEntryActionBar(
    this.libraryEntry,
    this.gameEntry, {
    super.key,
  });

  final LibraryEntry libraryEntry;
  final GameEntry? gameEntry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        children: [
          ReleaseDateChip(libraryEntry),
          const SizedBox(width: 8.0),
          ...actionButtons(context),
          const SizedBox(width: 16.0),
          if (gameEntry != null)
            ...linkButtons(context, libraryEntry, gameEntry!),
        ],
      ),
    );
  }

  List<Widget> actionButtons(BuildContext context) {
    final inWishlist = context.watch<WishlistModel>().contains(libraryEntry.id);

    return [
      GamePulse(libraryEntry, gameEntry),
      if (context.watch<UserModel>().isSignedIn) ...[
        IconButton(
          onPressed: () => AppConfigModel.isMobile(context)
              ? context.pushNamed('edit',
                  pathParameters: {'gid': '${libraryEntry.id}'})
              : EditEntryDialog.show(
                  context,
                  libraryEntry,
                  gameEntry: gameEntry,
                ),
          icon: Icon(
            Icons.edit,
            size: 24.0,
            color: Theme.of(context).colorScheme.secondary,
          ),
          splashRadius: 20.0,
        ),
        if (libraryEntry.storeEntries.isEmpty)
          IconButton(
            onPressed: () {
              if (inWishlist) {
                context
                    .read<WishlistModel>()
                    .removeFromWishlist(libraryEntry.id);
              } else {
                context.read<WishlistModel>().addToWishlist(libraryEntry);
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
    ];
  }

  List<Widget> linkButtons(
    BuildContext context,
    LibraryEntry libraryEntry,
    GameEntry gameEntry,
  ) {
    return [
      for (final label in const [
        'Official',
        'Igdb',
        'Wikipedia',
      ])
        for (final website
            in gameEntry.websites.where((site) => site.authority == label))
          SizedBox(
            height: 42,
            child: IconButton(
              onPressed: () async => await launchUrl(Uri.parse(website.url)),
              icon: websiteIcon(website.authority),
              splashRadius: 20.0,
            ),
          ),
      SizedBox(
        height: 42,
        child: IconButton(
          onPressed: () async => await launchUrl(Uri.parse(
              'https://www.metacritic.com/game/${gameEntry.igdbGame.url.split("/").last}')),
          icon: websiteIcon('Metacritic'),
          splashRadius: 20.0,
        ),
      ),
      for (final label in const ['Gog', 'Steam', 'Egs'])
        for (final website
            in gameEntry.websites.where((site) => site.authority == label))
          SizedBox(
            height: 48,
            child: IconButton(
              onPressed: () async => await launchUrl(Uri.parse(website.url)),
              icon: websiteIcon(website.authority,
                  disabled: libraryEntry.storeEntries.every(
                      (entry) => entry.storefront != label.toLowerCase())),
              splashRadius: 20.0,
            ),
          ),
    ];
  }

  Widget websiteIcon(String website, {bool disabled = false}) {
    return switch (website) {
      'Official' => const Icon(Icons.web),
      'Wikipedia' => Image.asset('assets/images/wikipedia-128.png'),
      'Igdb' => Image.asset('assets/images/igdb-128.png'),
      'Metacritic' => Image.asset('assets/images/metacritic-128.png'),
      'Gog' => Image.asset(
          'assets/images/gog-128.png',
          color: disabled ? Colors.grey[800]!.withOpacity(.8) : Colors.white,
          colorBlendMode: BlendMode.modulate,
        ),
      'Steam' => Image.asset(
          'assets/images/steam-128.png',
          color: disabled ? Colors.grey[800]!.withOpacity(.8) : Colors.white,
          colorBlendMode: BlendMode.modulate,
        ),
      'Egs' => Image.asset(
          'assets/images/egs-128.png',
          color: disabled ? Colors.grey[800]!.withOpacity(.8) : Colors.white,
          colorBlendMode: BlendMode.modulate,
        ),
      'Youtube' => Image.asset('assets/images/youtube-128.png'),
      _ => const Icon(Icons.error),
    };
  }
}

class RelatedGamesGroup extends StatelessWidget {
  const RelatedGamesGroup(this.title, this.gameDigests, {super.key});

  final String title;
  final List<GameDigest> gameDigests;

  @override
  Widget build(BuildContext context) {
    gameDigests.sort((a, b) => -a.releaseDate.compareTo(b.releaseDate));
    return SliverToBoxAdapter(
      child: TileCarousel(
        title: title,
        tileSize: AppConfigModel.isMobile(context)
            ? const TileSize(width: 133, height: 190)
            : const TileSize(width: 227, height: 320),
        tiles: gameDigests
            .map((digest) => TileData(
                  image:
                      '${Urls.imageProvider}/t_cover_big/${digest.cover}.jpg',
                  onTap: () => context.pushNamed('details',
                      pathParameters: {'gid': '${digest.id}'}),
                ))
            .toList(),
      ),
    );
  }
}
