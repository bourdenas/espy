import 'dart:collection';

import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/calendar/calendar_grid.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarViewDaily extends StatelessWidget {
  const CalendarViewDaily(
    this.libraryEntries, {
    super.key,
    this.startDate,
    this.leadingWeeks = 2,
    this.trailingWeeks = 15,
  });

  final Iterable<LibraryEntry> libraryEntries;
  final DateTime? startDate;
  final int leadingWeeks;
  final int trailingWeeks;

  @override
  Widget build(BuildContext context) {
    final today = startDate ?? DateTime.now().toUtc();
    final fromDate = today
        .subtract(Duration(
            days: today.weekday - 1)) // Get to the Monday of this week.
        .subtract(Duration(days: leadingWeeks * 7 + 1));
    final toDate = today
        .subtract(Duration(days: today.weekday - 1))
        .add(Duration(days: (trailingWeeks + 1) * 7 + 1));

    final libraryEntries = this.libraryEntries.where((entry) {
      final releaseDate = entry.digest.release;
      return releaseDate.isAfter(fromDate) && releaseDate.isBefore(toDate);
    });

    final refinement = context.watch<RefinementModel>().refinement;
    final refinedEntries = libraryEntries.where((e) => refinement.pass(e));

    final dailyReleases = HashMap<String, List<GameDigest>>();
    for (final entry in refinedEntries) {
      final key = DateFormat('yMMMd').format(
          DateTime.fromMillisecondsSinceEpoch(entry.releaseDate * 1000));
      dailyReleases.putIfAbsent(key, () => []).add(entry.digest);
    }
    for (final entries in dailyReleases.values) {
      entries.sort((a, b) =>
          b.scores.popularity?.compareTo(a.scores.popularity ?? 0) ??
          b.scores.hype?.compareTo(a.scores.hype ?? 0) ??
          0);
    }

    final entries = <CalendarGridEntry>[];
    final gridTiles = (leadingWeeks + 1 + trailingWeeks) * 7;
    for (int i = 0; i < gridTiles; ++i) {
      final label =
          DateFormat('yMMMd').format(fromDate.add(Duration(days: i + 1)));
      entries.add(CalendarGridEntry(
        label,
        dailyReleases[label] ?? [],
        onClick: (CalendarGridEntry entry) {
          context.read<CustomViewModel>().digests = entry.digests;
          context.pushNamed('view');
        },
      ));
    }

    return CalendarGrid(
      entries,
      selectedLabel: DateFormat('yMMMd').format(today),
    );
  }
}

const kPaddingWidthLimit = 2000;
