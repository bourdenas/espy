// import 'dart:ui' as ui;

import 'package:espy/modules/models/game_library_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatelessWidget {
  GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final games = context.watch<GameLibraryModel>().games;
    return Column(
      children: [
        if (games.length > 0) ...[
          // Material(
          //     elevation: 2,
          //     shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(4)),
          //     clipBehavior: Clip.antiAlias,
          //     child: BackdropFilter(
          //       filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          //       child: Image.network(
          //         'https://images.igdb.com/igdb/image/upload/t_720p/${games[12].game.screenshots[0].imageId}.jpg',
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
                Expanded(
                  child: Image.network(
                    'https://images.igdb.com/igdb/image/upload/t_cover_big/${games[12].game.cover.imageId}.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(padding: EdgeInsets.all(8)),
                Column(
                  children: [
                    Center(
                      child: Text(games[12].game.name,
                          style: Theme.of(context).textTheme.headline3),
                    ),
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
              ],
            ),
          ),
          Padding(padding: EdgeInsets.all(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(padding: EdgeInsets.all(64)),
              Expanded(child: Text(games[12].game.summary)),
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
              childAspectRatio: 1.33,
              children: [
                for (final screenshot in games[12].game.screenshots)
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
      ],
    );
  }
}
