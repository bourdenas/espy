import 'package:espy/modules/dialogs/image_dialog.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:flutter/material.dart';

class GameImageGallery extends StatelessWidget {
  const GameImageGallery({Key? key, required this.gameEntry}) : super(key: key);

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    return TileCarousel(
      tiles: gameEntry.screenshotData
          .map(
            (e) => TileData(
              image: e.thumbnail,
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => ImageDialog(imageUrl: e.full)),
            ),
          )
          .toList(),
      tileSize: TileSize(width: 320, height: 240),
    );
  }
}

class _ImageData {
  _ImageData(this.thumbnail, this.full);

  String thumbnail;
  String full;
}
