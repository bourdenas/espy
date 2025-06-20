import 'package:animate_do/animate_do.dart';
import 'package:espy/modules/models/frontpage_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/pages/timeline/timeline_utils.dart';
import 'package:espy/widgets/tiles/tile_size.dart';
import 'package:espy/widgets/tiles/tile_pile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:uuid/uuid.dart';

class TimelineCarousel extends StatelessWidget {
  final TileSize tileSize;

  const TimelineCarousel({
    super.key,
    this.tileSize = const TileSize(width: 227.0, height: 320.0),
  });

  @override
  Widget build(BuildContext context) {
    final releases = context.watch<FrontpageModel>().timeline;

    var startIndex = 0;
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    for (final release in releases) {
      if (release.games.first.releaseDate <= now) {
        break;
      }
      ++startIndex;
    }

    return startIndex == 0
        ? const Column()
        : FadeIn(
            duration: const Duration(milliseconds: 500),
            child: Column(
              children: [
                SizedBox(
                  height: tileSize.height * 1.5,
                  child: Timeline.tileBuilder(
                    controller: ScrollController(
                        initialScrollOffset: (startIndex - 2) * tileSize.width),
                    theme: TimelineThemeData(
                      direction: Axis.horizontal,
                      connectorTheme: const ConnectorThemeData(
                        space: 30.0,
                        thickness: 5.0,
                      ),
                    ),
                    shrinkWrap: true,
                    builder: TimelineTileBuilder.connected(
                      contentsAlign: ContentsAlign.reverse,
                      itemCount: releases.length,
                      itemExtent: tileSize.width + 16,
                      connectorBuilder: (context, index, connectorType) =>
                          connectorBuilder(context, releases, index),
                      indicatorBuilder: (context, index) => buttonBuilder(
                        context,
                        releases,
                        index,
                        now.round(),
                        () {
                          final id = Uuid().v4();
                          context
                              .read<LibraryViewModel>()
                              .add(id, releases[index].games);
                          context.pushNamed(
                            'view',
                            queryParameters: {
                              'title': releases[index].label,
                              'view': id
                            },
                          );
                        },
                      ),
                      nodePositionBuilder: (context, index) => .85,
                      contentsBuilder: (context, index) =>
                          TilePile(releases[index].games, maxSize: tileSize),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
