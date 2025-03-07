import 'dart:collection';

import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/library/library_grid_card.dart';
import 'package:espy/pages/library/library_stats.dart';
import 'package:espy/widgets/shelve.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarView extends StatefulWidget {
  const CalendarView(
    this.entries, {
    super.key,
  });

  final Iterable<LibraryEntry> entries;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  int pastWeeks = 1;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toUtc(); // see note below
    final todayLabel = DateFormat('yMMMd').format(today);
    // Get to the Monday of this week.
    var fromDate = today.subtract(Duration(days: today.weekday - 1));
    fromDate = fromDate.subtract(Duration(days: pastWeeks * 7));

    final entryMap = HashMap<String, LibraryEntry>.fromEntries(widget.entries
        .map((entry) => MapEntry(
            DateFormat('yMMMd').format(
                DateTime.fromMillisecondsSinceEpoch(entry.releaseDate * 1000)),
            entry)));

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
            expansion: LibraryStats(widget.entries),
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
                final date = fromDate.add(Duration(days: index));
                final dateLabel = DateFormat('yMMMd').format(date);
                final libraryEntry = entryMap[dateLabel];
                return Container(
                  alignment: Alignment.topLeft,
                  color: dateLabel == todayLabel ? Colors.teal : null,
                  // child: Text(DateFormat('MMM').format(date)),
                  child: libraryEntry != null
                      ? LibraryGridCard(libraryEntry)
                      : Text(DateFormat('MMMd').format(date)),
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
