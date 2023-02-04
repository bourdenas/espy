import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:espy/pages/home/slate_tile.dart';
import 'package:flutter/material.dart';

class HomeStack extends StatefulWidget {
  final String title;
  final VoidCallback? onExpand;
  final Iterable<SlateTileData> tiles;

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
  List<double> deckAngles = narrowDeckAngles;
  List<Offset> deckOffsets = narrowDeckOffsets;

  static const wideDeckAngles = <double>[
    math.pi / 12,
    -math.pi / 12,
    math.pi / 24,
    -math.pi / 24,
    0,
  ];
  static const narrowDeckAngles = <double>[
    math.pi / 32,
    -math.pi / 32,
    math.pi / 48,
    -math.pi / 48,
    0,
  ];

  static const narrowDeckOffsets = [
    Offset(16, 0),
    Offset(-16, 0),
    Offset(8, 0),
    Offset(-8, 0),
    Offset(0, -8),
  ];
  static const wideDeckOffsets = [
    Offset(32, 0),
    Offset(-32, 0),
    Offset(16, 0),
    Offset(-16, 0),
    Offset(0, -16),
  ];

  @override
  Widget build(BuildContext context) {
    final tiles = widget.tiles.take(5).toList().reversed.toList().asMap();
    return InkWell(
      onTap: () => widget.onExpand!(),
      onHover: (isHovering) => setState(() {
        deckAngles = isHovering ? wideDeckAngles : narrowDeckAngles;
        deckOffsets = isHovering ? wideDeckOffsets : narrowDeckOffsets;
      }),
      child: Column(
        children: [
          Stack(
            children: [
              for (final index_tile in tiles.entries)
                Transform.translate(
                  offset: deckOffsets[index_tile.key],
                  child: Transform.rotate(
                    angle: deckAngles[index_tile.key],
                    origin: Offset(0, 150),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      child: CachedNetworkImage(
                        fit: BoxFit.fill,
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
          SizedBox(
            height: 24,
          ),
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headline6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
