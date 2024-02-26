import 'dart:math';

import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/pages/timeline/timeline_utils.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timelines/timelines.dart';

class TimelineCarousel extends StatelessWidget {
  final TileSize tileSize;

  const TimelineCarousel({
    super.key,
    this.tileSize = const TileSize(width: 227.0, height: 320.0),
  });

  @override
  Widget build(BuildContext context) {
    final releases = context.watch<TimelineModel>().releases;

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
                        () => context.pushNamed(
                          'releases',
                          pathParameters: {
                            'label': releases[index].label,
                            'year': releases[index].year,
                          },
                        ),
                      ),
                      nodePositionBuilder: (context, index) => .85,
                      contentsBuilder: (context, index) => ReleaseStack(
                          releases[index].games,
                          maxSize: tileSize),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}

class ReleaseStack extends StatefulWidget {
  const ReleaseStack(this.games, {super.key, required this.maxSize});

  final Iterable<GameDigest> games;
  final TileSize maxSize;

  @override
  State<ReleaseStack> createState() => _ReleaseStackState();
}

class _ReleaseStackState extends State<ReleaseStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.maxSize.width,
      height: widget.maxSize.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final (index, game) in widget.games.indexed.take(5))
            Transform.translate(
              offset: _offset(
                  index, context.read<TimelineModel>().highlightScore(game)),
              child: _gameCover(
                  context,
                  game,
                  widget.maxSize.width *
                      context.read<TimelineModel>().highlightScore(game)),
            ),
        ].reversed.toList(),
      ),
    );
  }

  Widget _gameCover(BuildContext context, GameDigest game, double width) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        child: GestureDetector(
          onTap: () => context
              .pushNamed('details', pathParameters: {'gid': '${game.id}'}),
          child: Center(
            child: CachedNetworkImage(
              fit: BoxFit.cover,
              imageUrl: '${Urls.imageProvider}/t_cover_big/${game.cover}.jpg',
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error_outline)),
            ),
          ),
        ),
      ),
    );
  }

  Offset _offset(int index, double pop) {
    final coverWidth = widget.maxSize.width * pop;
    final coverHeight = widget.maxSize.height * pop;

    if (widget.games.length == 1) {
      return const Offset(0, 0);
    } else if (widget.games.length == 2) {
      return index == 0
          ? Offset(-((widget.maxSize.width - coverWidth) / 2),
              -((widget.maxSize.height - coverHeight) / 2))
          : Offset((widget.maxSize.width - coverWidth) / 2,
              ((widget.maxSize.height - coverHeight) / 2));
    }

    double progress = (index as double) / min(widget.games.length, 5);
    return Offset(
        ((widget.maxSize.width - coverWidth) / 2) * sin(progress * 2 * pi),
        -((widget.maxSize.height - coverHeight) / 2) * cos(progress * 2 * pi));
  }
}
