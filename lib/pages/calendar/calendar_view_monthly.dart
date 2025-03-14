import 'dart:collection';

import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/calendar/calendar_grid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarViewMonthly extends StatefulWidget {
  const CalendarViewMonthly(
    this.libraryEntries, {
    super.key,
    this.startDate,
    this.leadingYears = 1,
    this.trailingYears = 1,
  });

  final Iterable<LibraryEntry> libraryEntries;
  final DateTime? startDate;
  final int leadingYears;
  final int trailingYears;

  @override
  State<CalendarViewMonthly> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarViewMonthly> {
  @override
  void initState() {
    super.initState();

    leadingYears = widget.leadingYears;
  }

  int leadingYears = 0;

  @override
  Widget build(BuildContext context) {
    final today = widget.startDate ?? DateTime.now().toUtc();

    final fromDate = DateTime(today.year - leadingYears, 1, 1);
    final toDate = DateTime(today.year + 1, 12, 31, 23, 59, 59);

    final libraryEntries = widget.libraryEntries.where((entry) {
      final releaseDate = entry.digest.release;
      return releaseDate.isAfter(fromDate) && releaseDate.isBefore(toDate);
    });

    final refinement = context.watch<RefinementModel>().refinement;
    final refinedEntries = libraryEntries.where((e) => refinement.pass(e));

    final entryMap = HashMap<String, List<LibraryEntry>>();
    for (final entry in refinedEntries) {
      final key = DateFormat('MMM y').format(
          DateTime.fromMillisecondsSinceEpoch(entry.releaseDate * 1000));
      entryMap.putIfAbsent(key, () => []).add(entry);
    }
    for (final entries in entryMap.values) {
      entries.sort((a, b) =>
          b.scores.popularity?.compareTo(a.scores.popularity ?? 0) ??
          b.scores.hype?.compareTo(a.scores.hype ?? 0) ??
          0);
    }

    final entries = <CalendarGridEntry>[];
    final gridTiles = (leadingYears + 1 + widget.trailingYears) * 14;
    for (int i = 0; i < gridTiles; ++i) {
      final month = fromDate.month + i % 14;
      final year = fromDate.year + i ~/ 14;

      if (month > 12) {
        entries.add(CalendarGridEntry.empty);
      } else {
        final label = DateFormat('MMM y').format(DateTime(year, month));
        entries.add(CalendarGridEntry(label, entryMap[label]?.first));
      }
    }

    return CalendarGrid(
      entries,
      onPull: () async {
        setState(() {
          leadingYears += 1;
        });
      },
      selectedLabel: DateFormat('MMM y').format(today),
    );
  }
}

const kPaddingWidthLimit = 2000;
