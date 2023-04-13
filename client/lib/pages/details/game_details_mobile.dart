import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/details/game_details_widgets.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:espy/widgets/gametags/game_tags_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class GameDetailsContentMobile extends StatelessWidget {
  const GameDetailsContentMobile({
    Key? key,
    required this.libraryEntry,
    required this.gameEntry,
  }) : super(key: key);

  final LibraryEntry libraryEntry;
  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    final backgroundImage = gameEntry.steamData != null &&
            gameEntry.steamData!.backgroundImage != null
        ? gameEntry.steamData!.backgroundImage!
        : gameEntry.artwork.isNotEmpty
            ? 'https://images.igdb.com/igdb/image/upload/t_720p/${gameEntry.artwork[0].imageId}.jpg'
            : '';

    final description = gameEntry.steamData != null
        ? gameEntry.steamData!.aboutTheGame
        : gameEntry.summary;

    return CustomScrollView(
      key: Key('gameDetailsScrollView'),
      slivers: [
        SliverAppBar(
          leading: Container(),
          pinned: true,
          expandedHeight: 250.0,
          flexibleSpace: FlexibleSpaceBar(
            background: FadeIn(
              duration: Duration(milliseconds: 500),
              child: _fadeShader(
                CachedNetworkImage(
                  width: MediaQuery.of(context).size.width,
                  imageUrl: backgroundImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeInUp(
            from: 20,
            duration: Duration(milliseconds: 500),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gameEntry.name,
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  SizedBox(height: 8.0),
                  if (!kReleaseMode)
                    Column(
                      children: [
                        Text(
                          'game id: ${gameEntry.id}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 8.0),
                      ],
                    ),
                  GameEntryActionBar(
                    libraryEntry: libraryEntry,
                    gameEntry: gameEntry,
                  ),
                  SizedBox(height: 16.0),
                  GameTags(gameEntry: gameEntry),
                  SizedBox(height: 16.0),
                  if (!AppConfigModel.isMobile(context))
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GameTagsField(gameEntry.id),
                      ],
                    ),
                  SizedBox(height: 16.0),
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
                  SizedBox(height: 8.0),
                  if (gameEntry.genres.isNotEmpty)
                    Text(
                      'Genres: ${gameEntry.genres.join(', ')}',
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
                      'Keywords: ${gameEntry.keywords.join(', ')}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  SizedBox(height: 16.0),
                  if (gameEntry.expansions.isNotEmpty) ...[
                    RelatedGamesGroup(
                      'Expansions',
                      gameEntry.expansions,
                    ),
                    SizedBox(height: 16.0),
                  ],
                  if (gameEntry.dlcs.isNotEmpty) ...[
                    RelatedGamesGroup(
                      'DLCs',
                      gameEntry.dlcs,
                    ),
                    SizedBox(height: 16.0),
                  ],
                  if (gameEntry.remasters.isNotEmpty) ...[
                    RelatedGamesGroup(
                      'Remasters',
                      gameEntry.remasters,
                    ),
                    SizedBox(height: 16.0),
                  ],
                  if (gameEntry.remakes.isNotEmpty) ...[
                    RelatedGamesGroup(
                      'Remakes',
                      gameEntry.remakes,
                    ),
                    SizedBox(height: 16.0),
                  ],
                  screenshots(context),
                  SizedBox(height: 8.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget screenshots(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Screenshots',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
            ],
          ),
        ),
        CarouselSlider(
          options: CarouselOptions(
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {},
          ),
          items: [
            for (final screenshot in gameEntry.screenshots)
              CachedNetworkImage(
                imageUrl:
                    '${Urls.imageProvider}/t_720p/${screenshot.imageId}.jpg',
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Icon(Icons.error),
              )
          ],
        ),
      ],
    );
  }

  static Widget _fadeShader(Widget child) {
    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0.0, 0.5, 1.0, 1.0],
        ).createShader(
          Rect.fromLTRB(0.0, 0.0, rect.width, rect.height),
        );
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
