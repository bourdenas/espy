import 'dart:math';

import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/pages/calendar/calendar_grid.dart';
import 'package:espy/pages/calendar/calendar_grid_entry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class CalendarViewYear extends StatelessWidget {
  const CalendarViewYear(
    this.games, {
    super.key,
    this.startYear,
    this.endYear,
    this.onClick,
  });

  final Iterable<GameDigest> games;
  final int? startYear;
  final int? endYear;
  final Future<void> Function(CalendarGridEntry)? onClick;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toUtc();

    final years = chunkByYear(games);
    final (startYear, endYear) = (
      this.startYear ?? years.keys.reduce(max),
      this.endYear ?? years.keys.where((year) => year > 1970).reduce(min)
    );

    final entries = <CalendarGridEntry>[];
    entries.add(CalendarGridEntry(
      'TBA',
      years[1970] ?? [],
      onClick: onClick != null
          ? onClick!
          : (CalendarGridEntry entry) async {
              final id = Uuid().v4();
              context.read<LibraryViewModel>().add(id, entry.digests);
              context.pushNamed(
                'view',
                queryParameters: {'title': 'TBA', 'view': id},
              );
            },
    ));

    for (int year = startYear; year >= endYear; --year) {
      final games = years[year] ?? [];
      entries.add(CalendarGridEntry(
        '$year',
        games,
        onClick: onClick != null
            ? onClick!
            : (CalendarGridEntry entry) async {
                final id = Uuid().v4();
                context.read<LibraryViewModel>().add(id, entry.digests);
                context.pushNamed(
                  'view',
                  queryParameters: {'title': '$year', 'view': id},
                );
              },
      ));
    }

    return CalendarGrid(
      entries,
      gridCount: 6,
      selectedLabel: DateFormat('y').format(today),
    );
  }
}

Map<int, List<GameDigest>> chunkByYear(Iterable<GameDigest> games) {
  final years = <int, List<GameDigest>>{};
  for (final game in games) {
    years.putIfAbsent(game.releaseYear, () => []).add(game);
  }
  for (final games in years.values) {
    games.sort((l, r) => r.prominence.compareTo(l.prominence));
  }
  return years;
}

const kPaddingWidthLimit = 2000;
