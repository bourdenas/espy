import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/pages/calendar/calendar_grid_entry.dart';
import 'package:espy/widgets/tiles/tile_size.dart';
import 'package:espy/widgets/tiles/tile_pile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CalendarCard extends StatelessWidget {
  const CalendarCard(
    this.calendarEntry, {
    super.key,
    this.overlays = const [],
  });

  final CalendarGridEntry calendarEntry;
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridTile(
        child: coverImage(context),
      ),
    );
  }

  Widget coverImage(BuildContext context) {
    final covers = calendarEntry.covers;
    final behindFoldGames = calendarEntry.digests.length - covers.length;

    return Material(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            TilePile(covers, maxSize: TileSize(width: 227.0, height: 320.0)),
            ...overlays,
            if (covers.length + behindFoldGames > 1)
              BehindFoldBadge(calendarEntry),
          ],
        ),
      ),
    );
  }

  Widget cardTile(BuildContext context, GameDigest digest) {
    return Expanded(
      child: digest.id != 0
          ? InkWell(
              onTap: () => context.pushNamed('details',
                  pathParameters: {'gid': '${digest.id}'}),
              child: Image.network(
                '${Urls.imageProvider}/t_cover_big/${digest.cover}.jpg',
              ),
            )
          : Container(),
    );
  }
}

class BehindFoldBadge extends StatefulWidget {
  const BehindFoldBadge(this.calendarEntry, {super.key});

  final CalendarGridEntry calendarEntry;

  @override
  State<BehindFoldBadge> createState() => _BehindFoldBadgeState();
}

class _BehindFoldBadgeState extends State<BehindFoldBadge> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 4,
      left: 4,
      child: MouseRegion(
        onEnter: (_) => setState(() {
          hover = true;
        }),
        onExit: (_) => setState(() {
          hover = false;
        }),
        child: FloatingActionButton(
          backgroundColor: const Color(0x00FFFFFF),
          onPressed: () => widget.calendarEntry.onClick(widget.calendarEntry),
          child: Icon(
            hover
                ? Icons.arrow_circle_right
                : Icons.arrow_circle_right_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 56,
          ),
        ),
      ),
    );
  }
}
