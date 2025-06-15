import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/frontpage_model.dart';
import 'package:espy/widgets/tiles/tile_size.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TileStack extends StatelessWidget {
  const TileStack(this.games, {super.key, required this.maxSize});

  final Iterable<GameDigest> games;
  final TileSize maxSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxSize.width,
      height: maxSize.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final (index, game) in games.indexed.take(5))
            Transform.translate(
              offset: _offset(
                  index, context.read<FrontpageModel>().highlightScore(game)),
              child: _gameCover(
                  context,
                  game,
                  maxSize.width *
                      context.read<FrontpageModel>().highlightScore(game)),
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
}
