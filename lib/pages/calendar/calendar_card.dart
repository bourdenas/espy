import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/pages/calendar/calendar_grid_entry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quiver/iterables.dart';

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
    final covers = calendarEntry.getCovers();
    final behindFoldGames = calendarEntry.digests.length - covers.length;
    if (covers.length < 4 && !covers.first.isMain) {
      covers.addAll(range(4 - covers.length)
          .map((_) => GameDigest(id: 0, name: 'padding')));
    }

    return ExpandingWidget(
      scale: 1.1,
      child: Material(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              tiledCovers(context, covers),
              ...overlays,
              if (behindFoldGames > 0) behindFoldBadge(behindFoldGames),
            ],
          ),
        ),
      ),
    );
  }

  Positioned behindFoldBadge(int behindFoldGames) {
    return Positioned(
      bottom: 8,
      right: 4,
      child: ExpandingWidget(
        scale: 1.2,
        child: InkWell(
          onTap: () => calendarEntry.onClick(calendarEntry),
          child: SizedBox(
            width: 64,
            height: 64,
            child: CircleAvatar(
              backgroundColor: Color.fromRGBO(0, 0, 0, .7),
              child: Text('+ $behindFoldGames'),
            ),
          ),
        ),
      ),
    );
  }

  Widget tiledCovers(BuildContext context, List<GameDigest> covers) {
    return Column(
      children: switch (covers.length) {
        1 => [cardTile(context, covers.first)],
        2 => [
            Expanded(
              child: Row(
                children: [
                  for (final digest in covers.take(2)) cardTile(context, digest)
                ],
              ),
            ),
          ],
        3 => [
            Expanded(
              child: Row(
                children: [
                  for (final digest in covers.take(1)) cardTile(context, digest)
                ],
              ),
            ),
            Flexible(
              child: Row(
                children: [
                  for (final digest in covers.skip(1).take(2))
                    cardTile(context, digest)
                ],
              ),
            ),
          ],
        _ => [
            Expanded(
              child: Row(
                children: [
                  for (final digest in covers.take(2)) cardTile(context, digest)
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  for (final digest in covers.skip(2).take(2))
                    cardTile(context, digest)
                ],
              ),
            ),
          ],
      },
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

class ExpandingWidget extends StatefulWidget {
  final Widget child;
  final double scale;

  const ExpandingWidget({super.key, required this.child, this.scale = 1.1});

  @override
  State<ExpandingWidget> createState() => _ExpandingWidgetState();
}

class _ExpandingWidgetState extends State<ExpandingWidget>
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
    animation = Tween(begin: 1.0, end: widget.scale).animate(CurvedAnimation(
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
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return ScaleTransition(
            scale: animation,
            child: widget.child,
          );
        },
      ),
    );
  }
}
