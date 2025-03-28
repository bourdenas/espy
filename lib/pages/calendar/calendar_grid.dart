import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/calendar/calendar_card.dart';
import 'package:flutter/material.dart';

class CalendarGridEntry {
  static CalendarGridEntry empty = CalendarGridEntry(null, [], onClick: (_) {});

  const CalendarGridEntry(this.label, this.digests, {required this.onClick});

  final String? label;
  final List<GameDigest> digests;
  final void Function(CalendarGridEntry) onClick;
}

class CalendarGrid extends StatelessWidget {
  const CalendarGrid(
    this.entries, {
    super.key,
    this.gridCount = 7,
    this.selectedLabel,
  });

  final List<CalendarGridEntry> entries;
  final int gridCount;
  final String? selectedLabel;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        SliverCrossAxisGroup(
          slivers: [
            if (MediaQuery.of(context).size.width > kPaddingWidthLimit)
              SliverToBoxAdapter(child: Container()),
            SliverCrossAxisExpanded(
              flex: 8,
              sliver: SliverConstrainedCrossAxis(
                maxExtent: 1800,
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    mainAxisSpacing: 10.0,
                    crossAxisSpacing: 10.0,
                    childAspectRatio:
                        AppConfigModel.gridCardContraints.cardAspectRatio,
                    crossAxisCount: gridCount,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final entry = entries[index];
                      return Container(
                        alignment: Alignment.topLeft,
                        color: entry.label == selectedLabel
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: calendarTile(entry),
                      );
                    },
                    childCount: entries.length,
                  ),
                ),
              ),
            ),
            if (MediaQuery.of(context).size.width > kPaddingWidthLimit)
              SliverToBoxAdapter(child: Container()),
          ],
        ),
      ],
    );
  }

  Widget calendarTile(CalendarGridEntry entry) {
    if (entry.digests.isNotEmpty) {
      return CalendarCard(
        entry,
        overlays: [
          Positioned(
            top: -1,
            left: -1,
            child: Container(
              color: Color.fromRGBO(0, 0, 0, .7),
              padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Text(entry.label!),
            ),
          ),
        ],
      );
    }
    if (entry.label != null) {
      return Padding(
        padding: const EdgeInsets.all(7),
        child: Container(
          color: Color.fromRGBO(0, 0, 0, .7),
          padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Text(entry.label!),
        ),
      );
    }
    return Container();
  }
}

const kPaddingWidthLimit = 2000;
