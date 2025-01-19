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
import 'package:espy/pages/details/game_keywords.dart';
import 'package:espy/pages/details/game_updates.dart';
import 'package:espy/pages/details/screenshots_carousel.dart';
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
        child: CustomScrollView(
          primary: true,
          slivers: [
            GameDetailsHeader(libraryEntry, gameEntry),
            GameDetailsActionBar(gameEntry, libraryEntry),
            if (gameEntry != null) _GameDetailsBody(gameEntry!),
          ],
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(flex: 3, child: leftPane(context)),
          ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 32, maxWidth: 320)),
          GameDescription(gameEntry: gameEntry),
          ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 32, maxWidth: 320)),
          Flexible(flex: 2, child: rightPane(context)),
        ],
      ),
    );
  }

  Widget leftPane(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: CustomScrollView(
          primary: false,
          shrinkWrap: true,
          slivers: [
            ScreenshotsCarousel(gameEntry),
            if (gameEntry.steamData?.news.isNotEmpty ?? false)
              GameUpdates(gameEntry: gameEntry),
          ],
        ),
      ),
    );
  }

  Widget rightPane(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
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
            GameKeywords(gameEntry),
          ],
        ),
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        elevation: 10,
        color: AppConfigModel.gameDetailsBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TODO: This can often cause repetition with the begining of the
                // longer description. Find a better place to show it.
                if (gameEntry.steamData != null) ...[
                  Html(
                    data: gameEntry.steamData!.shortDescription,
                  ),
                  const SizedBox(height: 8.0),
                ],
                Html(
                  data: description,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GameDetailsActionBar extends StatelessWidget {
  const GameDetailsActionBar(this.gameEntry, this.libraryEntry, {super.key});

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
            // if (gameEntry != null) GameImageGallery(gameEntry!),
            // const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}

class GameDetailsHeader extends StatelessWidget {
  const GameDetailsHeader(this.libraryEntry, this.gameEntry, {super.key});

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
