import 'dart:collection';

import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/frontpage_model.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:espy/widgets/tiles/tile_size.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';

// Unused timeline view for years. Consider repurposing.
class AnnualView extends StatelessWidget {
  const AnnualView({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    final releases = context.watch<FrontpageModel>().timeline;

    final digests = releases.map((event) => event.games).expand((e) => e);
    final gamesByYear = HashMap<int, List<GameDigest>>();
    for (final digest in digests) {
      gamesByYear.putIfAbsent(digest.releaseYear, () => []).add(digest);
    }

    final timeline = [TimelineEntry('TBA', gamesByYear[1970] ?? [])];
    final (startYear, endYear) = (DateTime.now().year + 1, 1980);
    for (int year = startYear; year >= endYear; --year) {
      timeline.add(TimelineEntry('$year', gamesByYear[year] ?? []));
    }

    return Timeline.tileBuilder(
      primary: true,
      shrinkWrap: true,
      // reverse: true,
      builder: TimelineTileBuilder.connected(
        itemCount: releases.length,
        itemExtent: isMobile ? 240.0 : 370.0,
        connectorBuilder: (context, index, connectorType) => SolidLineConnector(
          thickness: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
        indicatorBuilder: (context, index) => SizedBox(
          width: 64,
          child: IconButton.outlined(
            icon: Text(
              timeline[index].label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            // color: Theme.of(context).colorScheme.errorContainer,
            color: Colors.red,
            onPressed: () {},
          ),
        ),
        nodePositionBuilder: (context, index) => .02,
        contentsBuilder: (context, index) {
          final digests = timeline[index].digests;
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

class TimelineEntry {
  const TimelineEntry(this.label, this.digests);

  final String label;
  final List<GameDigest> digests;
}
