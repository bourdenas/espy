import 'package:espy/constants/urls.dart';
import 'package:espy/pages/calendar/calendar_grid.dart';
import 'package:flutter/material.dart';

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
            // footer: cardFooter(appConfig),
            child: coverImage(context),
          ),
        ),
      ),
    );
  }

  Widget coverImage(BuildContext context) {
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
                  for (final digest in widget.calendarEntry.digests.take(2))
                    Expanded(
                      child: Image.network(
                        '${Urls.imageProvider}/t_cover_big/${digest.cover}.jpg',
                      ),
                    )
                ],
              ),
              Row(
                children: [
                  for (final digest
                      in widget.calendarEntry.digests.skip(2).take(2))
                    Expanded(
                      child: Image.network(
                        '${Urls.imageProvider}/t_cover_big/${digest.cover}.jpg',
                      ),
                    )
                ],
              ),
            ],
          ),
          ...widget.overlays
        ],
      ),
    );
  }
}
