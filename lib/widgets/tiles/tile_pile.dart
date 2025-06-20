import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/frontpage_model.dart';
import 'package:espy/widgets/tiles/tile_size.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TilePile extends StatefulWidget {
  const TilePile(this.games, {super.key, required this.maxSize});

  final Iterable<GameDigest> games;
  final TileSize maxSize;

  @override
  State<TilePile> createState() => _TilePileState();
}

class _TilePileState extends State<TilePile>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.ease,
      reverseCurve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => controller.forward(),
      onExit: (_) => controller.reverse(),
      child: SizedBox(
        width: widget.maxSize.width,
        height: widget.maxSize.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final (index, game) in widget.games.indexed.take(5))
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final coverScale = FrontpageModel.coverScale(game);
                  return switch (widget.games.length) {
                    1 => Transform.scale(
                        scale: 1 + .2 * animation.value,
                        child: _gameCover(
                            context, game, widget.maxSize.width * coverScale),
                      ),
                    _ => Transform.translate(
                        offset: _offset(index, coverScale),
                        child: _gameCover(
                            context, game, widget.maxSize.width * coverScale),
                      ),
                  };
                },
              ),
          ].reversed.toList(),
        ),
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

  Offset _offset(int index, double scale) {
    final coverWidth = widget.maxSize.width * scale;
    final coverHeight = widget.maxSize.height * scale;

    if (widget.games.length == 2) {
      final animationOffset = -32 + 32 * animation.value;
      return index == 0
          ? Offset(-((widget.maxSize.width - coverWidth) / 2 + animationOffset),
              -((widget.maxSize.height - coverHeight) / 2 + animationOffset))
          : Offset((widget.maxSize.width - coverWidth) / 2 + animationOffset,
              ((widget.maxSize.height - coverHeight) / 2 + animationOffset));
    }

    final animationOffset = 32 * animation.value;
    double progress = (index as double) / min(widget.games.length, 5);
    return Offset(
        ((widget.maxSize.width - coverWidth) / 2 + animationOffset) *
            sin(progress * 2 * pi),
        -((widget.maxSize.height - coverHeight) / 2 + animationOffset) *
            cos(progress * 2 * pi));
  }
}
