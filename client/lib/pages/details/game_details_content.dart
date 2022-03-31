import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/edit_entry_dialog.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/home/home_slate.dart';
import 'package:espy/pages/home/slate_tile.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:espy/widgets/gametags/game_tags_field.dart';
import 'package:flutter/material.dart';

class GameDetailsContent extends StatelessWidget {
  const GameDetailsContent({
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
    var shownEntry = gameEntry;
    for (final id in childPath) {
      final gameId = int.tryParse(id) ?? 0;

      shownEntry = [
        shownEntry.expansions,
        shownEntry.dlcs,
        shownEntry.remakes,
        shownEntry.remasters,
      ].expand((e) => e).firstWhere((e) => e.id == gameId);
    }

    return AppConfigModel.isMobile(context)
        ? GameDetailsContentMobile(
            libraryEntry: libraryEntry,
            gameEntry: shownEntry,
            childPath: childPath)
        : Container();
  }
}

class GameDetailsContentMobile extends StatelessWidget {
  const GameDetailsContentMobile({
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
    return CustomScrollView(
      key: Key('gameDetailsScrollView'),
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 250.0,
          flexibleSpace: FlexibleSpaceBar(
            background: FadeIn(
              duration: Duration(milliseconds: 500),
              child: _fadeShader(
                CachedNetworkImage(
                  width: MediaQuery.of(context).size.width,
                  imageUrl:
                      '${Urls.imageProvider}/t_cover_big/${gameEntry.cover?.imageId}.jpg',
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
                  actionBar(context, gameEntry),
                  SizedBox(height: 16.0),
                  GameTags(libraryEntry),
                  SizedBox(height: 16.0),
                  if (!AppConfigModel.isMobile(context))
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GameTagsField(libraryEntry),
                      ],
                    ),
                  SizedBox(height: 16.0),
                  Text(
                    gameEntry.summary,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Franchise: Foo, Bar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  if (gameEntry.expansions.isNotEmpty ||
                      gameEntry.dlcs.isNotEmpty) ...[
                    expansions(context, gameEntry),
                    SizedBox(height: 16.0),
                  ],
                  SizedBox(height: 16.0),
                  if (gameEntry.remakes.isNotEmpty ||
                      gameEntry.remasters.isNotEmpty) ...[
                    remakes(context, gameEntry),
                    SizedBox(height: 16.0),
                  ],
                  screenshots(context, gameEntry),
                  SizedBox(height: 8.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget expansions(BuildContext context, GameEntry gameEntry) {
    return HomeSlate(
      title: 'Expansions & DLC',
      tiles: [gameEntry.expansions, gameEntry.dlcs]
          .expand((e) => e)
          .map((dlc) => SlateTileData(
                image: dlc.cover != null
                    ? '${Urls.imageProvider}/t_cover_big/${dlc.cover!.imageId}.jpg'
                    : null,
                title: dlc.cover == null ? dlc.name : null,
                onTap: () => Navigator.pushNamed(context, '/details',
                    arguments:
                        [libraryEntry.id, ...childPath, dlc.id].join(',')),
              ))
          .toList(),
    );
  }

  Widget remakes(BuildContext context, GameEntry gameEntry) {
    return HomeSlate(
      title: 'Remakes',
      tiles: [gameEntry.remakes, gameEntry.remasters]
          .expand((e) => e)
          .map((remake) => SlateTileData(
                image: remake.cover != null
                    ? '${Urls.imageProvider}/t_cover_big/${remake.cover!.imageId}.jpg'
                    : null,
                title: remake.cover == null ? remake.name : null,
                onTap: () => Navigator.pushNamed(context, '/details',
                    arguments:
                        [libraryEntry.id, ...childPath, remake.id].join(',')),
              ))
          .toList(),
    );
  }

  Widget screenshots(BuildContext context, GameEntry gameEntry) {
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
                  "Screenshots",
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

  Widget actionBar(BuildContext context, GameEntry gameEntry) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            actionButtons(context),
            SizedBox(width: 16.0),
            Container(
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
            ),
          ],
        ),
        linkButtons(context, gameEntry),
      ],
    );
  }

  Widget actionButtons(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => AppConfigModel.isMobile(context)
              ? Navigator.pushNamed(context, '/edit',
                  arguments: '${libraryEntry.id}')
              : EditEntryDialog.show(context, libraryEntry),
          icon: Icon(
            Icons.edit,
            size: 24.0,
          ),
          splashRadius: 20.0,
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.favorite_border_outlined,
            color: Colors.red,
            size: 24.0,
          ),
          splashRadius: 20.0,
        ),
      ],
    );
  }

  Widget linkButtons(BuildContext context, GameEntry gameEntry) {
    return Row(
      children: [
        for (final website in gameEntry.websites)
          if (website.authority != "Null" && website.authority != "Youtube")
            IconButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/web', arguments: website.url),
              icon: websiteIcon(website.authority),
              splashRadius: 20.0,
            )
      ],
    );
  }

  Widget websiteIcon(String website) {
    switch (website) {
      case "Official":
        return Icon(Icons.web);
      case "Wikipedia":
        return Image.asset('assets/images/wikipedia-128.png');
      case "Igdb":
        return Image.asset('assets/images/igdb-128.png');
      case "Gog":
        return Image.asset('assets/images/gog-128.png');
      case "Steam":
        return Image.asset('assets/images/steam-128.png');
      case "Egs":
        return Image.asset('assets/images/egs-128.png');
      case "Youtube":
        return Image.asset('assets/images/youtube-128.png');
    }
    return Icon(Icons.error);
  }

  Widget _fadeShader(Widget child) {
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
