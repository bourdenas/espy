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

class TimelineView extends StatelessWidget {
  const TimelineView({super.key, required this.year});

  final String year;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    final today = DateFormat('d MMM').format(DateTime.now());

    return FutureBuilder(
      future: context.watch<TimelineModel>().gamesIn(year),
      builder: (BuildContext context,
          AsyncSnapshot<List<(DateTime, GameDigest)>> snapshot) {
        return snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData
            ? timeline(today, snapshot.data!, isMobile)
            : Container();
      },
    );
  }

  Timeline timeline(
      String today, List<(DateTime, GameDigest)> games, bool isMobile) {
    final yearNum = int.parse(year);

    return Timeline.tileBuilder(
      builder: TimelineTileBuilder.connectedFromStyle(
        itemCount: 12,
        connectorStyleBuilder: (context, index) => ConnectorStyle.solidLine,
        indicatorStyleBuilder: (context, index) =>
            today == DateFormat('d MMM').format(games[index].$1)
                ? IndicatorStyle.dot
                : IndicatorStyle.outlined,
        nodePositionBuilder: (context, index) => isMobile ? .2 : .06,
        contentsBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: TileCarousel(
            tileSize: isMobile
                ? const TileSize(width: 133, height: 190)
                : const TileSize(width: 227, height: 320),
            tiles: games
                .where((e) => e.$1.month == (index + 1))
                .map((e) => e.$2)
                .where((digest) =>
                    yearNum < 2006 ||
                    (digest.scores.popularityTier != 'Niche' &&
                        digest.scores.popularityTier != 'Fringe'))
                .map((digest) => TileData(
                      image:
                          '${Urls.imageProvider}/t_cover_big/${digest.cover}.jpg',
                      onTap: () => context.pushNamed('details',
                          pathParameters: {'gid': '${digest.id}'}),
                    ))
                .toList(),
          ),
        ),
        oppositeContentsBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: IconButton.outlined(
            icon: Text(months[index]),
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}

const months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];
