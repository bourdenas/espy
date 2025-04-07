import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/pages/calendar/calendar_grid_entry.dart';
import 'package:flutter/material.dart';
import 'package:quiver/iterables.dart';

class CalendarCard extends StatefulWidget {
  const CalendarCard(
    this.calendarEntry, {
    super.key,
    this.overlays = const [],
  });

  final CalendarGridEntry calendarEntry;
  final List<Widget> overlays;

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard>
    with SingleTickerProviderStateMixin {
  bool hover = false;
  late AnimationController controller;
  late Animation animation;
  late Animation padding;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    animation = Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(
        parent: controller, curve: Curves.ease, reverseCurve: Curves.easeIn));
    padding = Tween(begin: 0.0, end: -12.5).animate(CurvedAnimation(
        parent: controller, curve: Curves.ease, reverseCurve: Curves.easeIn));
    controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => widget.calendarEntry.onClick(widget.calendarEntry),
        onHover: (val) => setState(() {
          hover = val;
          if (hover) {
            controller.forward();
          } else {
            controller.reverse();
          }
        }),
        child: Container(
          transform: Matrix4(animation.value, 0, 0, 0, 0, animation.value, 0, 0,
              0, 0, 1, 0, padding.value, padding.value, 0, 1),
          child: GridTile(
            child: coverImage(context),
          ),
        ),
      ),
    );
  }

  Widget coverImage(BuildContext context) {
    final covers = widget.calendarEntry.getCovers();
    final behindFoldGames = widget.calendarEntry.digests.length - covers.length;
    if (covers.length < 4 && !covers.first.isMain) {
      covers.addAll(range(4 - covers.length)
          .map((_) => GameDigest(id: 0, name: 'padding')));
    }

    return Material(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Row(
                children: [
                  for (final digest in covers.take(2))
                    Expanded(
                      child: digest.id != 0
                          ? Image.network(
                              '${Urls.imageProvider}/t_cover_big/${digest.cover}.jpg',
                            )
                          : Container(),
                    )
                ],
              ),
              Row(
                children: [
                  for (final digest in covers.skip(2).take(2))
                    Expanded(
                      child: digest.id != 0
                          ? Image.network(
                              '${Urls.imageProvider}/t_cover_big/${digest.cover}.jpg',
                            )
                          : Container(),
                    )
                ],
              ),
            ],
          ),
          ...widget.overlays,
          if (behindFoldGames > 0)
            Positioned(
              bottom: 8,
              right: 4,
              child: SizedBox(
                width: 64,
                height: 64,
                child: CircleAvatar(
                  backgroundColor: Color.fromRGBO(0, 0, 0, .7),
                  child: Text('+ $behindFoldGames'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
