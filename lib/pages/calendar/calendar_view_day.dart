import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/pages/calendar/calendar_grid.dart';
import 'package:espy/pages/calendar/calendar_grid_entry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class CalendarViewDay extends StatelessWidget {
  const CalendarViewDay(
    this.games, {
    super.key,
    this.startDate,
    this.leadingWeeks = 2,
    this.trailingWeeks = 2,
  });

  final Iterable<GameDigest> games;
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
    final dailyReleases = chunkByDay(games);

    final entries = <CalendarGridEntry>[];
    final weeks = leadingWeeks + 1 + trailingWeeks;
    final gridTiles = weeks * 7;
    for (int i = 0; i < gridTiles; ++i) {
      final label =
          DateFormat('yMMMd').format(fromDate.add(Duration(days: i + 1)));
      entries.add(CalendarGridEntry(
        label,
        dailyReleases[label] ?? [],
        onClick: (CalendarGridEntry entry) {
          final id = Uuid().v4();
          context.read<LibraryViewModel>().add(id, entry.digests);
          context.pushNamed(
            'view',
            queryParameters: {'title': label, 'view': id},
          );
        },
      ));
    }

    final finalEntries = <CalendarGridEntry>[];
    for (int i = 0; i < weeks; ++i) {
      final week = <CalendarGridEntry>[];
      for (int j = 0; j < 7; ++j) {
        week.add(entries.removeLast());
      }
      finalEntries.addAll(week.reversed);
    }

    return CalendarGrid(
      finalEntries,
      selectedLabel: DateFormat('yMMMd').format(today),
    );
  }

  Map<String, List<GameDigest>> chunkByDay(Iterable<GameDigest> games) {
    final days = <String, List<GameDigest>>{};
    for (final game in games) {
      final key = DateFormat('yMMMd')
          .format(DateTime.fromMillisecondsSinceEpoch(game.releaseDate * 1000));
      days.putIfAbsent(key, () => []).add(game);
    }
    for (final digests in days.values) {
      digests.sort((l, r) => r.prominence.compareTo(l.prominence));
    }
    return days;
  }
}

const kPaddingWidthLimit = 2000;
