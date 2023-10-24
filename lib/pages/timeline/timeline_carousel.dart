import 'dart:math';

import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/frontpage_model.dart';
import 'package:flutter/material.dart';
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
    final now = DateTime.now();
    now.add(const Duration(days: 1));

    final gamesByDate = context.watch<FrontpageModel>().gamesByDate;

    return Column(
      children: [
        FadeIn(
          duration: const Duration(milliseconds: 500),
          child: SizedBox(
            height: widget.tileSize.height * 3,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              // padding: const EdgeInsets.symmetric(horizontal: 16.0),
              // itemCount: widget.tiles.length,
              itemBuilder: (context, index) {
                final date =
                    DateFormat('yMMMd').format(now.add(Duration(days: index)));

                return _TimelineEntry(
                  date: now.add(Duration(days: index)),
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

final _random = Random();

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
          child: (games.isNotEmpty) ? Text('${date.day}') : null,
        ),
      ],
    );
  }

  double rand(int min, int max) => (min + _random.nextInt(max - min)) as double;

  Widget _releaseEvent(BuildContext context) {
    return SizedBox(
      width: maxSize.width,
      height: maxSize.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final game in games)
            Transform.translate(
              offset: Offset(rand(-46, 46), rand(-128, 128)),
              child: _gameCover(context, game, games.length),
            ),
        ],
      ),
    );
  }

  Widget _gameCover(BuildContext context, GameDigest game, int sizef) {
    return SizedBox(
      width: maxSize.width * (1 - min(.2 * (sizef - 1), .7)),
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
