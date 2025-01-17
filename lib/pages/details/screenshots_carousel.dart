import 'dart:math';

import 'package:espy/modules/dialogs/image_dialog.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:flutter/material.dart';

class ScreenshotsCarousel extends StatelessWidget {
  const ScreenshotsCarousel(this.gameEntry, {super.key});

  final GameEntry gameEntry;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          header(context),
          SizedBox(height: 8),
          SizedBox(
            height: 380,
            child: CarouselView.weighted(
              itemSnapping: true,
              enableSplash: false,
              flexWeights: [1, 7, 1],
              controller: CarouselController(
                  initialItem:
                      Random().nextInt(gameEntry.screenshotData.length)),
              onTap: (index) => showDialog(
                context: context,
                builder: (context) =>
                    ImageDialog(imageUrl: gameEntry.screenshotData[index].full),
              ),
              children: [
                for (final image in gameEntry.screenshotData)
                  CarouselTile(image.thumbnail),
              ],
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget header(BuildContext context) {
    return Material(
      elevation: 10.0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          children: [
            InkWell(
              onTap: () {},
              child: Text(
                'Screenshots',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CarouselTile extends StatelessWidget {
  const CarouselTile(this.thumbUrl, {super.key});

  final String thumbUrl;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    return ClipRect(
      child: OverflowBox(
        maxWidth: width * 7 / 8,
        minWidth: width * 7 / 8,
        child: Image(
          fit: BoxFit.fitHeight,
          image: NetworkImage(thumbUrl),
        ),
      ),
    );
  }
}
