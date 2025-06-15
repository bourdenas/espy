import 'dart:math' as math;

import 'package:flutter/material.dart';

class TileFan extends StatefulWidget {
  final String title;
  final VoidCallback? onExpand;
  final Iterable<String> tileImages;

  const TileFan({
    super.key,
    required this.title,
    required this.tileImages,
    this.onExpand,
  });

  @override
  State<TileFan> createState() => _TileFanState();
}

class _TileFanState extends State<TileFan> {
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
    final tiles = widget.tileImages.take(5).toList().reversed.toList().asMap();
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
              for (final indexImage in tiles.entries)
                Transform.translate(
                  offset: deckOffsets[indexImage.key],
                  child: Transform.rotate(
                    angle: deckAngles[indexImage.key],
                    origin: const Offset(0, 150),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: Image.network(indexImage.value),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
