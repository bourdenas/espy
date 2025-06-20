import 'package:espy/modules/dialogs/image_dialog.dart';
import 'package:espy/modules/dialogs/video_dialog.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:espy/widgets/tiles/tile_size.dart';
import 'package:flutter/material.dart';

class GameImageGallery extends StatelessWidget {
  const GameImageGallery(this.gameEntry, {super.key});

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    return TileCarousel(
      tiles: [
        ...gameEntry.movieData.map((e) => TileData(
              image: e.thumbnail,
              title: e.name,
              onTap: () => showDialog(
                context: context,
                builder: (context) => VideoDialog(e.webm.max),
              ),
            )),
        ...gameEntry.screenshotData.map(
          (e) => TileData(
            image: e.thumbnail,
            onTap: () => showDialog(
              context: context,
              builder: (context) => ImageDialog(imageUrl: e.full),
            ),
          ),
        ),
      ],
      tileSize: const TileSize(width: 320, height: 240),
    );
  }
}
