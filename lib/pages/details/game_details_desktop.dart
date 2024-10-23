import 'dart:ui';

import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/debug_dialog.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/dialogs/image_dialog.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/intents/edit_dialog_intent.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/details/game_details_widgets.dart';
import 'package:espy/pages/details/game_image_gallery.dart';
import 'package:espy/widgets/gametags/espy_chips_details_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class GameDetailsContentDesktop extends StatelessWidget {
  const GameDetailsContentDesktop(this.libraryEntry, this.gameEntry,
      {super.key});

  final LibraryEntry libraryEntry;
  final GameEntry? gameEntry;

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
        child: Container(
          color: AppConfigModel.gameDetailsBackgroundColor,
          child: CustomScrollView(
            primary: true,
            slivers: [
              _GameDetailsHeader(libraryEntry, gameEntry),
              _GameDetailsActionBar(gameEntry, libraryEntry),
              if (gameEntry != null) _GameDetailsBody(gameEntry!),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameDetailsBody extends StatelessWidget {
  const _GameDetailsBody(this.gameEntry);

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
          if (gameEntry.contents.isNotEmpty)
            RelatedGamesGroup('Contains', gameEntry.contents),
        ],
      ),
    );
  }
}

class GameDescription extends StatelessWidget {
  const GameDescription({
    super.key,
    required this.gameEntry,
  });

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    final description = gameEntry.steamData != null
        ? gameEntry.steamData!.aboutTheGame
        : gameEntry.igdbGame.summary;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO: This can often cause repetition with the begining of the
          // longer description. Find a better place to show it.
          if (gameEntry.steamData != null) ...[
            Html(
              data: gameEntry.steamData?.shortDescription,
            ),
            const SizedBox(height: 8.0),
          ],
          Html(
            data: description,
          ),
          const SizedBox(height: 8.0),
          if (gameEntry.igdbGenres.isNotEmpty)
            Text(
              'Genres: ${gameEntry.igdbGenres.join(", ")}',
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
          const SizedBox(height: 4.0),
          if ((gameEntry.steamData?.userTags ?? []).isNotEmpty)
            Text(
              'Steam: ${gameEntry.steamData?.userTags.join(", ")}',
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

class _GameDetailsActionBar extends StatelessWidget {
  const _GameDetailsActionBar(this.gameEntry, this.libraryEntry);

  final GameEntry? gameEntry;
  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GameEntryActionBar(libraryEntry, gameEntry),
            const SizedBox(height: 16.0),
            if (gameEntry != null) GameImageGallery(gameEntry!),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}

class _GameDetailsHeader extends StatelessWidget {
  const _GameDetailsHeader(this.libraryEntry, this.gameEntry);

  final LibraryEntry libraryEntry;
  final GameEntry? gameEntry;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      leading: Container(),
      pinned: true,
      expandedHeight: 320.0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            headerImage(gameEntry?.steamData?.backgroundImage ?? ''),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  coverImage(context),
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

  Stack coverImage(BuildContext context) {
    final coverId = gameEntry?.cover?.imageId ?? libraryEntry.cover;
    final coverUrl = '${Urls.imageProvider}/t_cover_big/$coverId.jpg';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        coverId != null && coverId.isNotEmpty
            ? GestureDetector(
                child: Image.network(coverUrl),
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => ImageDialog(
                    imageUrl: coverUrl,
                    scale: .5,
                  ),
                ),
              )
            : Image.asset('assets/images/placeholder.png'),
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
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => DebugDialog(gameEntry: gameEntry!),
                    );
                  },
                  child: Text(
                    libraryEntry.name,
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (!kReleaseMode)
                Expanded(
                  child: Text(
                    '${libraryEntry.id}',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          const Padding(padding: EdgeInsets.all(16)),
          EspyChipsDetailsBar(
            gameEntry != null
                ? LibraryEntry.fromGameEntry(gameEntry!)
                : libraryEntry,
          ),
          const Padding(padding: EdgeInsets.all(8)),
        ],
      ),
    );
  }
}
