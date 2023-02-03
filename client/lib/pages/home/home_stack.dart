import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/pages/home/slate_tile.dart';
import 'package:flutter/material.dart';

class HomeStack extends StatefulWidget {
  final String title;
  final VoidCallback? onExpand;
  final List<SlateTileData> tiles;

  const HomeStack({
    Key? key,
    required this.title,
    this.onExpand,
    required this.tiles,
  }) : super(key: key);

  @override
  State<HomeStack> createState() => _HomeStackState();
}

class _HomeStackState extends State<HomeStack> {
  static const deckAngles = <double>[
    math.pi / 12,
    -math.pi / 12,
    math.pi / 24,
    -math.pi / 24,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    final tiles = widget.tiles.take(5).toList().reversed.toList().asMap();
    return InkWell(
      onTap: () => widget.onExpand!(),
      // onHover: (isHovering) => print(isHovering),
      child: Stack(
        children: [
          for (final index_tile in tiles.entries)
            Transform.translate(
              // offset: Offset(5.0 * index_tile.key, 3.0 * index_tile.key),
              offset: Offset(0, 0),
              child: Transform.rotate(
                angle: deckAngles[index_tile.key],
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  child: CachedNetworkImage(
                    fit: BoxFit.scaleDown,
                    imageUrl: index_tile.value.image!,
                    placeholder: (context, url) => Container(),
                    errorWidget: (context, url, error) =>
                        Center(child: Icon(Icons.error_outline)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
