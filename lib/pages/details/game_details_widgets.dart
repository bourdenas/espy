import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/user_data_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:espy/widgets/expandable_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class GameEntryActionBar extends StatelessWidget {
  const GameEntryActionBar(
    this.libraryEntry,
    this.gameEntry, {
    Key? key,
  }) : super(key: key);

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
          releaseYear(context),
          const SizedBox(width: 8.0),
          ...actionButtons(context),
          const SizedBox(width: 16.0),
          if (gameEntry != null)
            ...linkButtons(context, libraryEntry, gameEntry!),
        ],
      ),
    );
  }

  Widget releaseYear(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 2.0,
          horizontal: 8.0,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Text(
          '${DateTime.fromMillisecondsSinceEpoch(libraryEntry.releaseDate * 1000).year}',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget rating() {
    final rating = gameEntry?.igdbGame.rating ?? libraryEntry.rating;
    return ExpandableButton(
      offset: const Offset(0, 42),
      collapsedWidget: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.star,
            color: rating > 0 ? Colors.amber : Colors.grey,
            size: 18.0,
          ),
          const SizedBox(width: 4.0),
          Text(
            rating > 0 ? (5 * rating / 100.0).toStringAsFixed(1) : '--',
            // style: TextStyle(color: Colors.green),
          ),
        ],
      ),
      expansionBuilder: (context, _, onDone) {
        return _UserStarRating(libraryEntry, onDone);
      },
    );
  }

  List<Widget> actionButtons(BuildContext context) {
    final inWishlist = context.watch<WishlistModel>().contains(libraryEntry.id);

    return [
      rating(),
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
              context.read<WishlistModel>().removeFromWishlist(libraryEntry.id);
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

class _UserStarRating extends StatefulWidget {
  const _UserStarRating(
    this.libraryEntry,
    this.onDone, {
    super.key,
  });

  final LibraryEntry libraryEntry;
  final Function() onDone;

  @override
  State<_UserStarRating> createState() => _UserStarRatingState();
}

class _UserStarRatingState extends State<_UserStarRating> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 16,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            for (final i in List.generate(5, (i) => i))
              MouseRegion(
                onEnter: (_) {
                  setState(() {
                    selected = i + 1;
                  });
                },
                onExit: (_) {
                  setState(() {
                    selected = 0;
                  });
                },
                child: GestureDetector(
                  onTap: () {
                    widget.onDone();
                    context
                        .read<UserDataModel>()
                        .updateRating(widget.libraryEntry.id, i + 1);
                  },
                  child: Icon(
                    selected > i ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
      pushNavigation: false,
    );
  }
}
