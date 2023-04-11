import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/image_dialog.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/widgets/image_carousel.dart';
import 'package:flutter/material.dart';

class GameImageGallery extends StatelessWidget {
  const GameImageGallery({Key? key, required this.gameEntry}) : super(key: key);

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    final screenshots = gameEntry.steamData != null
        ? gameEntry.steamData!.screenshots
            .map(
              (e) => _ImageData(e.pathThumbnail, e.pathFull),
            )
            .toList()
        : gameEntry.screenshots
            .map(
              (e) => _ImageData(
                '${Urls.imageProvider}/t_720p/${e.imageId}.jpg',
                '${Urls.imageProvider}/t_1080p/${e.imageId}.jpg',
              ),
            )
            .toList();

    return ImageCarousel(
      tiles: screenshots
          .map(
            (e) => CarouselTileData(
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
