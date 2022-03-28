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
import 'package:provider/provider.dart';

class GameDetailsContent extends StatelessWidget {
  const GameDetailsContent({
    Key? key,
    required this.libraryEntry,
    required this.gameEntry,
  }) : super(key: key);

  final LibraryEntry libraryEntry;
  final GameEntry gameEntry;

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
                      '${Urls.imageProvider}/t_cover_big/${libraryEntry.cover}.jpg',
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
                  actionBar(context),
                  SizedBox(height: 16.0),
                  GameTags(libraryEntry),
                  SizedBox(height: 16.0),
                  if (!context.watch<AppConfigModel>().isMobile(context))
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
                  if (gameEntry.expansions.isNotEmpty) ...[
                    expansions(context),
                    SizedBox(height: 16.0),
                  ],
                  screenshots(),
                  SizedBox(height: 8.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget expansions(BuildContext context) {
    return HomeSlate(
      title: 'Expansions',
      tiles: gameEntry.expansions
          .map((gameEntry) => SlateTileData(
                image: gameEntry.cover != null
                    ? '${Urls.imageProvider}/t_cover_big/${gameEntry.cover!.imageId}.jpg'
                    : null,
                onTap: () => Navigator.pushNamed(context, '/details',
                    arguments: '${gameEntry.id}'),
              ))
          .toList(),
    );
  }

  CarouselSlider screenshots() {
    return CarouselSlider(
      options: CarouselOptions(
        enlargeCenterPage: true,
        onPageChanged: (index, reason) {},
      ),
      items: [
        for (final screenshot in gameEntry.screenshots)
          CachedNetworkImage(
            imageUrl: '${Urls.imageProvider}/t_720p/${screenshot.imageId}.jpg',
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => Icon(Icons.error),
          )
      ],
    );
  }

  Row actionBar(BuildContext context) {
    return Row(
      children: [
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
        SizedBox(width: 16.0),
        Row(
          children: [
            IconButton(
              onPressed: () => context.read<AppConfigModel>().isMobile(context)
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
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/web',
                  arguments: '${libraryEntry.id}'),
              icon: Image.asset('assets/images/gog-128.png'),
              splashRadius: 20.0,
            ),
            IconButton(
              onPressed: () {},
              icon: Image.asset('assets/images/steam-128.png'),
              splashRadius: 20.0,
            ),
          ],
        ),
      ],
    );
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
