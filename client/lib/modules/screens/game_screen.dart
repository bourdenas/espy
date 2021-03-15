// import 'dart:ui' as ui;

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
    return Column(
      children: [
        // Material(
        //     elevation: 2,
        //     shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(4)),
        //     clipBehavior: Clip.antiAlias,
        //     child: BackdropFilter(
        //       filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        //       child: Image.network(
        //         'https://images.igdb.com/igdb/image/upload/t_720p/${game.screenshots[0].imageId}.jpg',
        //         fit: BoxFit.cover,
        //         height: 200,
        //         width: 1200,
        //       ),
        //     )),
        Padding(padding: EdgeInsets.all(16)),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Image.network(
                'https://images.igdb.com/igdb/image/upload/t_cover_big/${entry.game.cover.imageId}.jpg',
                fit: BoxFit.cover,
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
                        FilterChip(
                            label: Text('4X'), onSelected: (selected) {}),
                        FilterChip(
                            label: Text('Strategy'), onSelected: (selected) {}),
                        FilterChip(
                            label: Text('Amplitude'),
                            onSelected: (selected) {}),
                        FilterChip(
                            label: Text('Turn-Based Strategy'),
                            onSelected: (selected) {}),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(padding: EdgeInsets.all(16)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(padding: EdgeInsets.all(64)),
            Expanded(child: Text(entry.game.summary)),
            Padding(padding: EdgeInsets.all(64)),
          ],
        ),
        Padding(padding: EdgeInsets.all(16)),
        Expanded(
          child: GridView.count(
            restorationId: 'game_screen_screenshot_offset',
            crossAxisCount: 1,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            padding: const EdgeInsets.all(16),
            childAspectRatio: entry.game.screenshots.isNotEmpty
                ? entry.game.screenshots[0].width /
                    entry.game.screenshots[0].height
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
          ),
        ),
      ],
    );
  }
}
