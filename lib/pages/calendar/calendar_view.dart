import 'dart:collection';

import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/library/library_grid_card.dart';
import 'package:espy/pages/library/library_stats.dart';
import 'package:espy/widgets/shelve.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarView extends StatefulWidget {
  const CalendarView(
    this.entries, {
    super.key,
    this.startDate,
  });

  final Iterable<LibraryEntry> entries;
  final DateTime? startDate;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  int pastWeeks = 1;

  @override
  Widget build(BuildContext context) {
    final today = widget.startDate ?? DateTime.now().toUtc();
    final todayLabel = DateFormat('yMMMd').format(today);

    final fromDate = today
        .subtract(Duration(
            days: today.weekday - 1)) // Get to the Monday of this week.
        .subtract(Duration(days: pastWeeks * 7 + 1));
    final toDate = today
        .subtract(Duration(days: today.weekday - 1))
        .add(Duration(days: 16 * 7 + 1));

    final entries = widget.entries.where((entry) {
      final releaseDate = entry.digest.release;
      return releaseDate.isAfter(fromDate) && releaseDate.isBefore(toDate);
    });

    final refinement = context.watch<RefinementModel>().refinement;
    final refinedEntries = entries.where((e) => refinement.pass(e));

    final entryMap = HashMap<String, List<LibraryEntry>>();
    for (final entry in refinedEntries) {
      final key = DateFormat('yMMMd').format(
          DateTime.fromMillisecondsSinceEpoch(entry.releaseDate * 1000));
      entryMap.putIfAbsent(key, () => []).add(entry);
    }
    for (final entries in entryMap.values) {
      entries.sort((a, b) =>
          b.scores.popularity?.compareTo(a.scores.popularity ?? 0) ??
          b.scores.hype?.compareTo(a.scores.hype ?? 0) ??
          0);
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          pastWeeks += 4;
        });
      },
      child: CustomScrollView(
        primary: true,
        shrinkWrap: true,
        slivers: [
          Shelve(
            title: 'Drill-down',
            expansion: LibraryStats(entries),
            color: Colors.amber,
            expanded: true,
          ),
          SliverAppBar(
            pinned: true,
            title: Padding(
              padding: const EdgeInsets.fromLTRB(0, 32, 0, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday',
                ].map((label) => Text(label)).toList(),
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
              childAspectRatio:
                  AppConfigModel.gridCardContraints.cardAspectRatio,
              crossAxisCount: 7,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final date = fromDate.add(Duration(days: index + 1));
                final dateLabel = DateFormat('yMMMd').format(date);
                final entries = entryMap[dateLabel];
                return Container(
                  alignment: Alignment.topLeft,
                  color: dateLabel == todayLabel
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: entries != null
                      ? LibraryGridCard(
                          entries.first,
                          overlays: [
                            Positioned(
                              top: -1,
                              left: -1,
                              child: Container(
                                color: Color.fromRGBO(0, 0, 0, .7),
                                padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                                child: Text(DateFormat('MMMd').format(date)),
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(7),
                          child: Container(
                            color: Color.fromRGBO(0, 0, 0, .7),
                            padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
                            child: Text(DateFormat('MMMd').format(date)),
                          ),
                        ),
                );
              },
              childCount: (pastWeeks + 16) * 7,
            ),
          ),
        ],
      ),
    );
  }
}
