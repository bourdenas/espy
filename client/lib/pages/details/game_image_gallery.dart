import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:flutter/material.dart';

class GameImageGallery extends StatelessWidget {
  const GameImageGallery({Key? key, required this.gameEntry}) : super(key: key);

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    final screenshots = gameEntry.steamData != null
        ? gameEntry.steamData!.screenshots
            .map(
              (e) => ImageData(e.pathThumbnail, e.pathFull),
            )
            .toList()
        : gameEntry.screenshots
            .map(
              (e) => ImageData(
                '${Urls.imageProvider}/t_720p/${e.imageId}.jpg',
                '${Urls.imageProvider}/t_1080p/${e.imageId}.jpg',
              ),
            )
            .toList();

    return SizedBox(
      height: 240,
      child: FadeIn(
        duration: Duration(milliseconds: 500),
        child: Container(
          height: ImageTileSize.height(AppConfigModel.isMobile(context)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: screenshots.length,
            itemBuilder: (context, index) {
              return ImageTile(screenshots[index]);
            },
          ),
        ),
      ),
    );
  }
}

class ImageData {
  ImageData(this.thumbnail, this.full);

  String thumbnail;
  String full;
}

class ImageTileSize {
  static const mobileWidth = 120.0;
  static const mobileHeight = 170.0;

  static const desktopWidth = 227.1;
  static const desktopHeight = 320.0;

  static double width(bool isMobile) {
    return isMobile ? mobileWidth : desktopWidth;
  }

  static double height(bool isMobile) {
    return isMobile ? mobileHeight : desktopHeight;
  }
}

class ImageTile extends StatelessWidget {
  const ImageTile(
    this.imageData, {
    Key? key,
  }) : super(key: key);

  final ImageData imageData;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(2),
              title: Container(
                decoration: BoxDecoration(),
                width: MediaQuery.of(context).size.width,
                child: Expanded(
                  child: CachedNetworkImage(
                    fit: BoxFit.cover,
                    imageUrl: imageData.full,
                    placeholder: (context, url) => Container(),
                    errorWidget: (context, url, error) =>
                        Center(child: Icon(Icons.error_outline)),
                  ),
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
          child: Stack(
            children: [
              CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: imageData.thumbnail,
                placeholder: (context, url) => Container(),
                errorWidget: (context, url, error) =>
                    Center(child: Icon(Icons.error_outline)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
