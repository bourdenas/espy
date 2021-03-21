// import 'dart:ui' as ui;
import 'package:espy/proto/library.pb.dart';
import 'package:espy/widgets/game_tags.dart';
import 'package:flutter/material.dart';

class GameDetails extends StatelessWidget {
  final GameEntry entry;

  GameDetails({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(
      slivers: [
        _HeaderSliver(entry),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return Container(
                padding: const EdgeInsets.all(32),
                child: Text(entry.game.summary),
              );
            },
            childCount: 1,
          ),
        ),
        _ScreenshotsSliver(entry),
      ],
    ));
  }
}

class _HeaderSliver extends StatelessWidget {
  final GameEntry entry;

  const _HeaderSliver(this.entry);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 320.0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(children: [
          // Material(
          //   elevation: 2,
          //   shape:
          //       RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          //   clipBehavior: Clip.antiAlias,
          //   child: BackdropFilter(
          //     filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          //     child: Image.network(
          //       'https://images.igdb.com/igdb/image/upload/t_720p/${entry.game.artworks[0].imageId}.jpg',
          //       fit: BoxFit.cover,
          //       height: 200,
          //       width: 1200,
          //     ),
          //   ),
          // ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: '${entry.game.id}_cover',
                  child: Image.network(
                    'https://images.igdb.com/igdb/image/upload/t_cover_big/${entry.game.cover.imageId}.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(padding: EdgeInsets.all(8)),
                Expanded(
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            entry.game.name,
                            style: Theme.of(context).textTheme.headline3,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        InputChip(
                          label: Icon(Icons.settings),
                          onPressed: () {},
                        ),
                      ]),
                      Padding(padding: EdgeInsets.all(16)),
                      GameTags(entry),
                    ],
                  ),
                ),
              ],
            ),
          )
        ]),
      ),
    );
  }
}

class _ScreenshotsSliver extends StatelessWidget {
  final GameEntry entry;

  const _ScreenshotsSliver(this.entry);

  @override
  Widget build(BuildContext context) {
    return SliverGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: entry.game.screenshots.isNotEmpty
          ? entry.game.screenshots[0].width / entry.game.screenshots[0].height
          : 1,
      children: [
        for (final screenshot in entry.game.screenshots)
          GridTile(
            child: Material(
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                'https://images.igdb.com/igdb/image/upload/t_720p/${screenshot.imageId}.jpg',
                fit: BoxFit.contain,
              ),
            ),
          ),
      ],
      // ),
    );
  }
}
