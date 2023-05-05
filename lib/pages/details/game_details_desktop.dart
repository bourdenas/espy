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
  }) : super(key: key);

  final LibraryEntry libraryEntry;
  final GameEntry gameEntry;

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
            GameDetailsBody(gameEntry: gameEntry),
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
  }) : super(key: key);

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 64),
          GameDescription(gameEntry: gameEntry),
          const SizedBox(width: 64),
          relatedGames(),
        ],
      ),
    );
  }

  Widget relatedGames() {
    return Expanded(
      child: SizedBox(
        height: 1200,
        child: CustomScrollView(
          primary: false,
          shrinkWrap: true,
          slivers: [
            if (gameEntry.parent != null)
              RelatedGamesGroup('Base Game', [gameEntry.parent!]),
            if (gameEntry.expansions.isNotEmpty)
              RelatedGamesGroup('Expansions', gameEntry.expansions),
            if (gameEntry.dlcs.isNotEmpty)
              RelatedGamesGroup('DLCs', gameEntry.dlcs),
            if (gameEntry.remasters.isNotEmpty)
              RelatedGamesGroup('Remasters', gameEntry.remasters),
            if (gameEntry.remakes.isNotEmpty)
              RelatedGamesGroup('Remakes', gameEntry.remakes),
          ],
        ),
      ),
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
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Html(
            data: description,
          ),
          const SizedBox(height: 8.0),
          if (gameEntry.genres.isNotEmpty)
            Text(
              'Genres: ${gameEntry.genres.join(", ")}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          const SizedBox(height: 4.0),
          if (gameEntry.keywords.isNotEmpty)
            Text(
              'Keywords: ${gameEntry.keywords.join(", ")}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}

class GameDetailsActionBar extends StatelessWidget {
  const GameDetailsActionBar(this.gameEntry, this.libraryEntry, {Key? key})
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
            GameEntryActionBar(gameEntry, libraryEntry),
            const SizedBox(height: 16.0),
            GameImageGallery(gameEntry: gameEntry),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}

class GameDetailsHeader extends StatelessWidget {
  const GameDetailsHeader(this.gameEntry, {Key? key}) : super(key: key);

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
                  const Padding(padding: EdgeInsets.all(8)),
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
          errorWidget: (context, url, error) => const Icon(Icons.error),
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
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
            ),
            if (!kReleaseMode)
              Expanded(
                child: Text(
                  '${gameEntry.id}',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
          ]),
          const Padding(padding: EdgeInsets.all(16)),
          GameTags(gameEntry: gameEntry),
        ],
      ),
    );
  }
}
