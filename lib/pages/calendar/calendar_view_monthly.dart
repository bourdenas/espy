import 'dart:collection';

import 'package:espy/modules/documents/calendar.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/years_model.dart';
import 'package:espy/pages/calendar/calendar_grid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarViewMonthly extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final today = startDate ?? DateTime.now().toUtc();

    final fromDate = DateTime(today.year - leadingYears, 1, 1);
    final toDate = DateTime(today.year + 1, 12, 31, 23, 59, 59);

    final libraryEntries = this.libraryEntries.where((entry) {
      final releaseDate = entry.digest.release;
      return releaseDate.isAfter(fromDate) && releaseDate.isBefore(toDate);
    });

    final refinement = context.watch<RefinementModel>().refinement;
    final refinedEntries = libraryEntries.where((e) => refinement.pass(e));

    final gridTiles = (leadingYears + 1 + trailingYears) * 14;

    return FutureBuilder(
      future: context.read<YearsModel>().getYears(
          List.generate(leadingYears + 1, (i) => '${today.year - i}')),
      builder: (BuildContext context,
          AsyncSnapshot<List<AnnualReviewDoc>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container();
        }

        final monthlyReleases = chunkByMonth(refinedEntries);
        if (snapshot.hasData) {
          for (final year in snapshot.data!) {
            monthlyReleases.addAll(chunkByMonth(year.releases
                .map((digest) => LibraryEntry.fromGameDigest(digest))));
          }
        }

        final entries = <CalendarGridEntry>[];
        for (int i = 0; i < gridTiles; ++i) {
          final month = fromDate.month + i % 14;
          final year = fromDate.year + i ~/ 14;

          if (month > 12) {
            entries.add(CalendarGridEntry.empty);
          } else {
            final label = DateFormat('MMM y').format(DateTime(year, month));
            entries.add(CalendarGridEntry(label, monthlyReleases[label] ?? []));
          }
        }

        return CalendarGrid(
          entries,
          selectedLabel: DateFormat('MMM y').format(today),
        );
      },
    );
  }

  HashMap<String, List<GameDigest>> chunkByMonth(
      Iterable<LibraryEntry> libraryEntries) {
    final entryMap = HashMap<String, List<GameDigest>>();
    for (final entry in libraryEntries) {
      final key = DateFormat('MMM y').format(
          DateTime.fromMillisecondsSinceEpoch(entry.releaseDate * 1000));
      entryMap.putIfAbsent(key, () => []).add(entry.digest);
    }
    for (final entries in entryMap.values) {
      entries.sort((a, b) =>
          b.scores.popularity?.compareTo(a.scores.popularity ?? 0) ??
          b.scores.hype?.compareTo(a.scores.hype ?? 0) ??
          0);
    }

    return entryMap;
  }
}

const kPaddingWidthLimit = 2000;
