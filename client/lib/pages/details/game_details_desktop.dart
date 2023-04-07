import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/intents/edit_dialog_intent.dart';
import 'package:espy/pages/details/game_details_widgets.dart';
import 'package:espy/pages/details/game_image_gallery.dart';
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
    return Actions(
      actions: {
        EditDialogIntent: CallbackAction<EditDialogIntent>(
            onInvoke: (intent) => EditEntryDialog.show(
                  context,
                  libraryEntry,
                  gameEntry: gameEntry,
                )),
      },
      child: Focus(
        autofocus: true,
        child: CustomScrollView(
          primary: true,
          slivers: [
            GameDetailsHeader(gameEntry),
            GameDetailsActionBar(gameEntry, libraryEntry),
            GameDetailsBody(gameEntry: gameEntry, gameEntryPath: childPath),
          ],
        ),
      ),
    );
  }
}

class GameDetailsBody extends StatelessWidget {
  const GameDetailsBody({
    Key? key,
    required this.gameEntry,
    required this.gameEntryPath,
  }) : super(key: key);

  final GameEntry gameEntry;
  final List<String> gameEntryPath;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 64),
          GameDescription(gameEntry: gameEntry),
          SizedBox(width: 64),
          relatedGames(
            gameEntry,
            ['${gameEntry.id}', ...gameEntryPath],
          )
        ],
      ),
    );
  }

  static Widget relatedGames(GameEntry gameEntry, List<String> gameEntryPath) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (gameEntry.expansions.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 900),
            child: RelatedGamesGroup(
                'Expansions', gameEntry.expansions, gameEntryPath),
          ),
        if (gameEntry.dlcs.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 900),
            child: RelatedGamesGroup('DLCs', gameEntry.dlcs, gameEntryPath),
          ),
        if (gameEntry.remasters.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 900),
            child: RelatedGamesGroup(
                'Remasters', gameEntry.remasters, gameEntryPath),
          ),
        if (gameEntry.remakes.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 900),
            child:
                RelatedGamesGroup('Remakes', gameEntry.remakes, gameEntryPath),
          ),
      ],
    );
  }
}

class GameDescription extends StatelessWidget {
  const GameDescription({
    Key? key,
    required this.gameEntry,
  }) : super(key: key);

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    final description = gameEntry.steamData != null
        ? gameEntry.steamData!.aboutTheGame
        : gameEntry.summary;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Html(
            data: description,
          ),
          SizedBox(height: 8.0),
          if (gameEntry.genres.isNotEmpty)
            Text(
              'Genres: ${gameEntry.genres.join(", ")}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          SizedBox(height: 4.0),
          if (gameEntry.keywords.isNotEmpty)
            Text(
              'Keywords: ${gameEntry.keywords.join(", ")}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          SizedBox(height: 16.0),
        ],
      ),
    );
  }
}

class GameDetailsActionBar extends StatelessWidget {
  GameDetailsActionBar(this.gameEntry, this.libraryEntry, {Key? key})
      : super(key: key);

  final GameEntry gameEntry;
  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GameEntryActionBar(
              libraryEntry: libraryEntry,
              gameEntry: gameEntry,
            ),
            SizedBox(height: 16.0),
            GameImageGallery(gameEntry: gameEntry),
            SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}

class GameDetailsHeader extends StatelessWidget {
  GameDetailsHeader(this.gameEntry, {Key? key}) : super(key: key);

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    final backgroundImage = gameEntry.steamData != null &&
            gameEntry.steamData!.backgroundImage != null
        ? gameEntry.steamData!.backgroundImage!
        : gameEntry.artwork.isNotEmpty
            ? 'https://images.igdb.com/igdb/image/upload/t_720p/${gameEntry.artwork[0].imageId}.jpg'
            : '';

    return SliverAppBar(
      leading: Container(),
      pinned: true,
      expandedHeight: 320.0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            headerImage(backgroundImage),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  coverImage(),
                  Padding(padding: EdgeInsets.all(8)),
                  gameTitle(context),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Stack coverImage() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CachedNetworkImage(
          imageUrl:
              '${Urls.imageProvider}/t_cover_big/${gameEntry.cover?.imageId}.jpg',
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
        // Positioned(
        //   right: 0,
        //   child: FloatingActionButton(
        //     mini: true,
        //     tooltip: 'Edit',
        //     child: Icon(Icons.edit),
        //     backgroundColor: Color.fromARGB(64, 255, 255, 255),
        //     onPressed: () {
        //       // GameEntryEditDialog.show(context, libraryEntry);
        //     },
        //   ),
        // ),
      ],
    );
  }

  Row headerImage(String backgroundImage) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  backgroundImage,
                ),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.0)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget gameTitle(BuildContext context) {
    return Expanded(
      child: Column(
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
          GameTags(gameEntry: gameEntry),
        ],
      ),
    );
  }
}
