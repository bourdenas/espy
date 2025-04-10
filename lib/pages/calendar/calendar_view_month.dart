import 'dart:collection';

import 'package:espy/modules/documents/calendar.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/years_model.dart';
import 'package:espy/pages/calendar/calendar_grid.dart';
import 'package:espy/pages/calendar/calendar_grid_entry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarViewMonth extends StatelessWidget {
  const CalendarViewMonth({
    super.key,
    this.startDate,
    this.yearsBack = 3,
    this.yearsForward = 0,
  });

  final DateTime? startDate;
  final int yearsBack;
  final int yearsForward;

  @override
  Widget build(BuildContext context) {
    final today = startDate ?? DateTime.now().toUtc();
    final toDate = DateTime(today.year + yearsForward, 12, 31, 23, 59, 59);

    final refinement = context.watch<RefinementModel>().refinement;
    final gridTiles = (yearsBack + 1 + yearsForward) * 12;

    return FutureBuilder(
      future: context
          .read<YearsModel>()
          .getYears(List.generate(yearsBack + 1, (i) => '${today.year - i}')),
      builder: (BuildContext context,
          AsyncSnapshot<List<AnnualReviewDoc>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container();
        }

        final gamesAcrossYears = <List<GameDigest>>[];
        if (snapshot.hasData) {
          for (final year in snapshot.data!) {
            gamesAcrossYears.add(year.releases);
          }
        }

        final refinedEntries =
            gamesAcrossYears.expand((e) => e).where((e) => refinement.pass(e));
        final monthlyReleases = chunkByMonth(refinedEntries);

        final entries = <CalendarGridEntry>[];
        for (int i = 0; i < gridTiles; ++i) {
          final month = 12 - (i % 12);
          final year = toDate.year - (i ~/ 12);

          final label = DateFormat('MMM y').format(DateTime(year, month));
          entries.add(CalendarGridEntry(
            label,
            monthlyReleases[label] ?? [],
            onClick: (CalendarGridEntry entry) {
              context.read<CustomViewModel>().digests = entry.digests;
              context.pushNamed('view');
            },
          ));
        }

        return CalendarGrid(
          entries,
          gridCount: 6,
          selectedLabel: DateFormat('MMM y').format(today),
        );
      },
    );
  }

  HashMap<String, List<GameDigest>> chunkByMonth(Iterable<GameDigest> games) {
    final entryMap = HashMap<String, List<GameDigest>>();
    for (final game in games) {
      final key = DateFormat('MMM y')
          .format(DateTime.fromMillisecondsSinceEpoch(game.releaseDate * 1000));
      entryMap.putIfAbsent(key, () => []).add(game);
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
