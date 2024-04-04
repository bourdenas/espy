import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/details/game_details_widgets.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:espy/widgets/shelve.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class GameDetailsContentMobile extends StatelessWidget {
  const GameDetailsContentMobile(this.libraryEntry, this.gameEntry,
      {super.key});

  final LibraryEntry libraryEntry;
  final GameEntry? gameEntry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _GameDetailsHeader(libraryEntry, gameEntry),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: GameEntryActionBar(libraryEntry, gameEntry),
          ),
        ),
        if (!kReleaseMode)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'game id: ${libraryEntry.id}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: GameTags(
              gameEntry != null
                  ? LibraryEntry.fromGameEntry(gameEntry!)
                  : libraryEntry,
            ),
          ),
        ),
        if (gameEntry != null) ...[
          Shelve(
            title: 'Screenshots',
            expansion: screenshots(context, gameEntry!),
          ),
          Shelve(
            title: 'Description',
            expansion: _GameDescription(gameEntry!),
          ),
          if (gameEntry!.parent != null)
            RelatedGamesGroup('Base Game', [gameEntry!.parent!]),
          if (gameEntry!.expansions.isNotEmpty)
            RelatedGamesGroup('Expansions', gameEntry!.expansions),
          if (gameEntry!.dlcs.isNotEmpty)
            RelatedGamesGroup('DLCs', gameEntry!.dlcs),
          if (gameEntry!.remasters.isNotEmpty)
            RelatedGamesGroup('Remasters', gameEntry!.remasters),
          if (gameEntry!.remakes.isNotEmpty)
            RelatedGamesGroup('Remakes', gameEntry!.remakes),
        ]
      ],
    );
  }

  Widget screenshots(BuildContext context, GameEntry gameEntry) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {},
          ),
          items: [
            for (final screenshot in gameEntry.screenshotData)
              CachedNetworkImage(
                imageUrl: screenshot.thumbnail,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              )
          ],
        ),
      ],
    );
  }
}

class _GameDescription extends StatelessWidget {
  const _GameDescription(this.gameEntry);

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    final description = gameEntry.steamData != null
        ? gameEntry.steamData!.aboutTheGame
        : gameEntry.igdbGame.summary;

    return Container(
      color: AppConfigModel.gameDetailsBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Html(
              data: description,
              style: {
                'html': Style(
                  fontSize: FontSize(14.0),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                )
              },
            ),
            const SizedBox(height: 8.0),
            if (gameEntry.genres.isNotEmpty)
              Text(
                'Genres: ${gameEntry.genres.join(', ')}',
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
                'Keywords: ${gameEntry.keywords.join(', ')}',
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
      // pinned: true,
      expandedHeight: 320.0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  coverImage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stack coverImage() {
    final coverId = gameEntry?.cover?.imageId ?? libraryEntry.cover;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        FadeIn(
          duration: const Duration(milliseconds: 500),
          child: CachedNetworkImage(
            imageUrl: '${Urls.imageProvider}/t_cover_big/$coverId.jpg',
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ],
    );
  }
}
