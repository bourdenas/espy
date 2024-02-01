import 'dart:math';

import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TileSize {
  const TileSize({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;
}

class TimelineCarousel extends StatelessWidget {
  final TileSize tileSize;

  const TimelineCarousel({
    super.key,
    this.tileSize = const TileSize(width: 227.0, height: 320.0),
  });

  @override
  Widget build(BuildContext context) {
    final shelves = context.watch<TimelineModel>().games;

    var startIndex = 0;
    final today = DateTime.now();
    for (final (release, _) in shelves) {
      if (release.compareTo(today) > 0) {
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
                  child: ScrollablePositionedList.builder(
                    itemCount: shelves.length,
                    initialScrollIndex:
                        startIndex > 1 ? startIndex - 2 : startIndex,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final (date, games) = shelves[index];
                      return _TimelineEntry(
                        date: date,
                        games: games,
                        maxSize: tileSize,
                        showMonth: index == 0,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.date,
    required this.games,
    required this.maxSize,
    this.showMonth = false,
  });

  final DateTime date;
  final List<GameDigest> games;
  final TileSize maxSize;
  final bool showMonth;

  @override
  Widget build(BuildContext context) {
    games.sort(
      (a, b) => -(a.scores.popularity ?? 0).compareTo(b.scores.popularity ?? 0),
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
              ? IconButton.outlined(
                  icon: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
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
              offset: _offset(
                  index, context.read<TimelineModel>().highlightScore(game)),
              child: _gameCover(
                  context,
                  game,
                  maxSize.width *
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
