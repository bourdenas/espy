import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/calendar_model.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/pages/calendar/calendar_grid.dart';
import 'package:espy/pages/calendar/calendar_grid_entry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarViewYear extends StatelessWidget {
  const CalendarViewYear({
    super.key,
    this.startYear,
    this.endYear,
    this.gamesByYear,
    this.onClick,
  });

  final int? startYear;
  final int? endYear;
  final Map<String, List<GameDigest>>? gamesByYear;
  final Future<void> Function(CalendarGridEntry)? onClick;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toUtc();
    final startYear = this.startYear ?? today.year + 1;

    return FutureBuilder(
      future: gamesByYear == null
          ? context.read<CalendarModel>().calendar
          : () async {
              return gamesByYear!;
            }(),
      builder: (BuildContext context,
          AsyncSnapshot<Map<String, List<GameDigest>>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return Container();
        }
        final calendar = snapshot.data!;

        final entries = [
          CalendarGridEntry(
            'TBA',
            calendar['1970'] ?? [],
            onClick: onClick != null
                ? onClick!
                : (CalendarGridEntry entry) async {
                    context.read<CustomViewModel>().digests = entry.digests;
                    context.pushNamed('view');
                  },
            coverExtractor: (games) => games.take(4).toList(),
          ),
        ];
        for (int year = startYear; year >= (endYear ?? 1979); --year) {
          final games = calendar['$year'] ?? [];
          entries.add(CalendarGridEntry(
            '$year',
            games,
            onClick: onClick != null
                ? onClick!
                : (CalendarGridEntry entry) async {
                    context.read<CustomViewModel>().digests = entry.digests;
                    context.pushNamed('view');
                  },
            coverExtractor: (games) {
              final scored = games
                  .where((digest) => (digest.scores.espyScore ?? 0) > 0)
                  .toList()
                ..sort((a, b) =>
                    b.scores.espyScore!.compareTo(a.scores.espyScore!));
              if (scored.isNotEmpty) {
                final highlyScored = scored
                    .where((digest) => digest.scores.espyScore! >= 80)
                    .length;
                if (highlyScored > 0 && highlyScored < 3) {
                  return [scored[0]];
                } else {
                  return scored.take(4).toList();
                }
              }
              return games.toList();
            },
          ));
        }

        return CalendarGrid(
          entries,
          gridCount: 6,
          selectedLabel: DateFormat('y').format(today),
        );
      },
    );
  }
}

const kPaddingWidthLimit = 2000;
