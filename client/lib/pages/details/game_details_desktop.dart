import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/pages/details/game_details_widgets.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class GameDetailsContentDesktop extends StatelessWidget {
  const GameDetailsContentDesktop({
    Key? key,
    required this.libraryEntry,
    required this.gameEntry,
    required this.childPath,
  }) : super(key: key);

  final LibraryEntry libraryEntry;
  final GameEntry gameEntry;
  final List<String> childPath;

  @override
  Widget build(BuildContext context) {
    final description = gameEntry.steamData != null
        ? gameEntry.steamData!.aboutTheGame
        : gameEntry.summary;

    return CustomScrollView(
      primary: true,
      slivers: [
        header(context, libraryEntry, gameEntry),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GameEntryActionBar(
                  libraryEntry: libraryEntry,
                  gameEntry: gameEntry,
                ),
                SizedBox(height: 16.0),
                relatedGames(
                  context,
                  gameEntry,
                  ['${libraryEntry.id}', ...childPath],
                ),
                SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600),
                child: Html(
                  data: description,
                ),
              ),
            ],
          ),
        ),
        screenshot(context, gameEntry),
      ],
    );
  }

  static Widget header(
      BuildContext context, LibraryEntry libraryEntry, GameEntry gameEntry) {
    final backgroundImage = gameEntry.steamData != null &&
            gameEntry.steamData!.backgroundImage != null
        ? gameEntry.steamData!.backgroundImage!
        : gameEntry.artwork.isNotEmpty
            ? 'https://images.igdb.com/igdb/image/upload/t_720p/${gameEntry.artwork[0].imageId}.jpg'
            : '';

    return SliverAppBar(
      pinned: true,
      expandedHeight: 320.0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: Image.network(
                    backgroundImage,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Hero(
                        tag: '${gameEntry.id}_cover',
                        child: CachedNetworkImage(
                          imageUrl:
                              '${Urls.imageProvider}/t_cover_big/${gameEntry.cover?.imageId}.jpg',
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: FloatingActionButton(
                          mini: true,
                          tooltip: 'Edit',
                          child: Icon(Icons.edit),
                          backgroundColor: Color.fromARGB(64, 255, 255, 255),
                          onPressed: () {
                            // GameEntryEditDialog.show(context, libraryEntry);
                          },
                        ),
                      ),
                    ],
                  ),
                  Padding(padding: EdgeInsets.all(8)),
                  Expanded(
                    child: gameTitle(context, libraryEntry, gameEntry),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  static Widget gameTitle(
      BuildContext context, LibraryEntry libraryEntry, GameEntry gameEntry) {
    return Column(
      children: [
        Row(children: [
          Expanded(
            child: Text(
              gameEntry.name,
              style: Theme.of(context).textTheme.headline3,
              textAlign: TextAlign.center,
            ),
          ),
          if (!kReleaseMode)
            Expanded(
              child: Text(
                '${gameEntry.id}',
                style: Theme.of(context).textTheme.headline5,
                textAlign: TextAlign.center,
              ),
            ),
        ]),
        Padding(padding: EdgeInsets.all(16)),
        GameTags(libraryEntry),
      ],
    );
  }

  static Widget relatedGames(
      BuildContext context, GameEntry gameEntry, List<String> idPath) {
    final hasExpansions =
        gameEntry.expansions.isNotEmpty || gameEntry.dlcs.isNotEmpty;
    final hasRemakes =
        gameEntry.remakes.isNotEmpty || gameEntry.remasters.isNotEmpty;

    return Row(
      children: [
        if (hasExpansions)
          Expanded(
            child: GameEntryExpansions(gameEntry, idPath: idPath),
          ),
        if (hasExpansions && hasRemakes) SizedBox(width: 64.0),
        if (hasRemakes)
          Expanded(
            child: GameEntryRemakes(gameEntry, idPath: idPath),
          ),
      ],
    );
  }

  static Widget screenshot(BuildContext context, GameEntry gameEntry) {
    return SliverGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: gameEntry.screenshots.isNotEmpty
          ? gameEntry.screenshots[0].width / gameEntry.screenshots[0].height
          : 1,
      children: [
        for (final screenshot in gameEntry.screenshots)
          GridTile(
            child: Material(
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl:
                    '${Urls.imageProvider}/t_720p/${screenshot.imageId}.jpg',
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          ),
      ],
    );
  }
}