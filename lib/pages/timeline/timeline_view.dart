import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timelines/timelines.dart';

/// This is an example of a timeline but it is not used atm.
/// It should be repurposed as a timeline view.
class TimelineView extends StatelessWidget {
  const TimelineView({super.key, this.year});

  final String? year;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    final today = DateFormat('d MMM').format(DateTime.now());
    final games = context.read<TimelineModel>().games;

    return timeline(context, today, games, isMobile);
  }

  Widget timeline(BuildContext context, String today,
      List<(DateTime, List<GameDigest>)> games, bool isMobile) {
    return Timeline.tileBuilder(
      builder: TimelineTileBuilder.connectedFromStyle(
        itemCount: games.length,
        connectorStyleBuilder: (context, index) => ConnectorStyle.solidLine,
        indicatorStyleBuilder: (context, index) =>
            today == DateFormat('d MMM').format(games[index].$1)
                ? IndicatorStyle.dot
                : IndicatorStyle.container,
        nodePositionBuilder: (context, index) => isMobile ? .2 : .06,
        contentsBuilder: (context, index) {
          final digests = games[index].$2;
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: TileCarousel(
              tileSize: isMobile
                  ? const TileSize(width: 133, height: 190)
                  : const TileSize(width: 227, height: 320),
              tiles: digests
                  .map((digest) => TileData(
                        image:
                            '${Urls.imageProvider}/t_cover_big/${digest.cover}.jpg',
                        onTap: () => context.pushNamed('details',
                            pathParameters: {'gid': '${digest.id}'}),
                      ))
                  .toList(),
            ),
          );
        },
        oppositeContentsBuilder: (context, index) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: IconButton.outlined(
              icon: Text(DateFormat('d MMM').format(games[index].$1)),
              onPressed: () {},
            )),
      ),
    );
  }
}
