import 'dart:ui' as ui;

import 'package:espy/proto/library.pb.dart';
import 'package:flutter/material.dart';

class GameDetailsPage extends Page {
  final GameEntry entry;

  GameDetailsPage({required this.entry}) : super(key: ValueKey(entry));

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (BuildContext context) {
        return GameScreen(entry: entry);
      },
    );
  }
}

class GameScreen extends StatelessWidget {
  final GameEntry entry;

  GameScreen({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _HeaderSliver(entry),
        _ScreenshotsSliver(entry),
      ],
    );
  }
}

class _HeaderSliver extends StatelessWidget {
  final GameEntry entry;

  const _HeaderSliver(this.entry);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      expandedHeight: 300.0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(children: [
          // Material(
          //   elevation: 2,
          //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          //   clipBehavior: Clip.antiAlias,
          //   child: BackdropFilter(
          //     filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          //     child: Image.network(
          //       'https://images.igdb.com/igdb/image/upload/t_720p/${entry.game.screenshots[0].imageId}.jpg',
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
                      Text(entry.game.name,
                          style: Theme.of(context).textTheme.headline3),
                      Padding(padding: EdgeInsets.all(16)),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: [
                          InputChip(
                            label: Text('4X'),
                            onPressed: () {},
                            onDeleted: () {},
                          ),
                          InputChip(
                            label: Text('Strategy'),
                            onPressed: () {},
                            onDeleted: () {},
                          ),
                          InputChip(
                            label: Text('Amplitude'),
                            onPressed: () {},
                            onDeleted: () {},
                          ),
                          InputChip(
                            label: Text('Turn-Based Strategy'),
                            onPressed: () {},
                            onDeleted: () {},
                          ),
                        ],
                      ),
                      Padding(padding: EdgeInsets.all(8)),
                      Expanded(child: Text(entry.game.summary)),
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
