import 'package:espy/constants/urls.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/pages/timeline/timeline_utils.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timelines/timelines.dart';

class TimelineView extends StatelessWidget {
  const TimelineView({super.key, this.scrollToLabel, this.year});

  final String? scrollToLabel;
  final String? year;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    final releases = context.watch<TimelineModel>().releases;
    // final today = DateFormat('d MMM').format(DateTime.now());

    int startIndex = 0;
    for (final release in releases) {
      if (release.label == scrollToLabel && release.year == year) {
        break;
      }
      ++startIndex;
    }

    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    final tileSize = isMobile ? 240.0 : 370.0;
    return Timeline.tileBuilder(
      shrinkWrap: true,
      controller: ScrollController(initialScrollOffset: startIndex * tileSize),
      builder: TimelineTileBuilder.connected(
        itemCount: releases.length,
        itemExtent: tileSize,
        connectorBuilder: (context, index, connectorType) =>
            connectorBuilder(context, releases, index),
        indicatorBuilder: (context, index) => buttonBuilder(
          context,
          releases,
          index,
          now.round(),
          () => context.pushNamed(
            'view',
            pathParameters: {
              'label': releases[index].label,
              'year': releases[index].year,
            },
          ),
        ),
        nodePositionBuilder: (context, index) => .02,
        contentsBuilder: (context, index) {
          final digests = releases[index].games;
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: TileCarousel(
              tileSize: isMobile
                  ? const TileSize(width: 133, height: 190)
                  : const TileSize(width: 227, height: 320),
              tiles: digests
                  .map((digest) => TileData(
                        // scale: context
                        //     .read<TimelineModel>()
                        //     .highlightScore(digest),
                        image:
                            '${Urls.imageProvider}/t_cover_big/${digest.cover}.jpg',
                        onTap: () => context.pushNamed('details',
                            pathParameters: {'gid': '${digest.id}'}),
                      ))
                  .toList(),
            ),
          );
        },
        // oppositeContentsBuilder: (context, index) {
        //   final now = DateTime.now().millisecondsSinceEpoch / 1000;

        //   return Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 8),
        //     child: releases[index].games.first.releaseDate <= now
        //         ? SizedBox(
        //             width: 4,
        //             child: Container(color: Colors.orangeAccent),
        //           )
        //         : Container(),
        //   );
        // },
      ),
    );
  }
}
