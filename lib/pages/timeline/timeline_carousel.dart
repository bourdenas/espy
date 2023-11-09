import 'dart:math';

import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TileSize {
  const TileSize({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;
}

class TimelineCarousel extends StatefulWidget {
  final TileSize tileSize;

  const TimelineCarousel({
    Key? key,
    this.tileSize = const TileSize(width: 227.0, height: 320.0),
  }) : super(key: key);

  @override
  State<TimelineCarousel> createState() => _TileCarouselState();
}

class _TileCarouselState extends State<TimelineCarousel> {
  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yMMMd').format(DateTime.now());
    final start = DateTime.now().subtract(const Duration(days: 6 * 30));
    final gamesByDate = context.watch<FrontpageModel>().gamesByDate;

    var pixelsToToday = -300.0;
    for (var i = 0; i < 6 * 30; ++i) {
      final date = DateFormat('yMMMd').format(start.add(Duration(days: i)));
      pixelsToToday +=
          gamesByDate(date).isNotEmpty ? widget.tileSize.width + 16 : 32;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(pixelsToToday,
          duration: const Duration(microseconds: 100), curve: Curves.bounceIn);
    });

    return Column(
      children: [
        FadeIn(
          duration: const Duration(milliseconds: 500),
          child: SizedBox(
            height: widget.tileSize.height * 1.4,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final date = DateFormat('yMMMd')
                    .format(start.add(Duration(days: index)));

                if (date == today) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -16,
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                              child: Text('today'),
                            ),
                            SizedBox(
                              height: widget.tileSize.height * 1.2,
                              child: Center(
                                child: Container(
                                  width: 3,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _TimelineEntry(
                        date: start.add(Duration(days: index)),
                        games: gamesByDate(date),
                        maxSize: widget.tileSize,
                        showMonth: index == 0,
                      ),
                    ],
                  );
                }

                return _TimelineEntry(
                  date: start.add(Duration(days: index)),
                  games: gamesByDate(date),
                  maxSize: widget.tileSize,
                  showMonth: index == 0,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  final ScrollController _scrollController = ScrollController();
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    Key? key,
    required this.date,
    required this.games,
    required this.maxSize,
    this.showMonth = false,
  }) : super(key: key);

  final DateTime date;
  final List<GameDigest> games;
  final TileSize maxSize;
  final bool showMonth;

  @override
  Widget build(BuildContext context) {
    games.sort(
      (a, b) => -a.popularity.compareTo(b.popularity),
    );

    return Column(
      children: [
        SizedBox(
          height: 32,
          child: (showMonth || date.day == 1)
              ? Text(DateFormat('MMM').format(date))
              : null,
        ),
        Stack(
          alignment: Alignment.topCenter,
          children: [
            if (games.isNotEmpty) ...[
              _connection(context, maxSize.width + 16),
              _releaseEvent(context),
            ] else
              _connection(context, 32),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: (games.isNotEmpty)
              ? IconButton.filled(
                  icon: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () {
                    context.pushNamed('releases', pathParameters: {
                      'date': '${date.millisecondsSinceEpoch}',
                    });
                  },
                )
              : null,
        ),
      ],
    );
  }

  Offset _offset(int index, double pop) {
    final coverWidth = maxSize.width * pop;
    final coverHeight = maxSize.height * pop;

    if (games.length == 1) {
      return const Offset(0, 0);
    } else if (games.length == 2) {
      return index == 0
          ? Offset(-((maxSize.width - coverWidth) / 2),
              -((maxSize.height - coverHeight) / 2))
          : Offset((maxSize.width - coverWidth) / 2,
              ((maxSize.height - coverHeight) / 2));
    }

    double progress = (index as double) / min(games.length, 5);
    return Offset(((maxSize.width - coverWidth) / 2) * sin(progress * 2 * pi),
        -((maxSize.height - coverHeight) / 2) * cos(progress * 2 * pi));
  }

  Widget _releaseEvent(BuildContext context) {
    return SizedBox(
      width: maxSize.width,
      height: maxSize.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final (index, game) in games.indexed.take(5))
            Transform.translate(
              offset: _offset(index,
                  context.read<FrontpageModel>().normalizePopularity(game)),
              child: _gameCover(
                  context,
                  game,
                  maxSize.width *
                      context.read<FrontpageModel>().normalizePopularity(game)),
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
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error_outline)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _connection(BuildContext context, double width) {
    return SizedBox(
      height: maxSize.height,
      child: Center(
        child: Container(
          height: 5,
          width: width,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
