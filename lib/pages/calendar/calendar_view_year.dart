import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/models/calendar_model.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/pages/calendar/calendar_grid.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarViewYear extends StatelessWidget {
  const CalendarViewYear({
    super.key,
    this.startDate,
    this.leadingYears = 25,
    this.trailingYears = 1,
    this.gamesByYear,
    this.onClick,
  });

  final DateTime? startDate;
  final int leadingYears;
  final int trailingYears;
  final Map<String, List<GameDigest>>? gamesByYear;
  final Future<void> Function(CalendarGridEntry)? onClick;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toUtc();
    final startDate = this.startDate ?? today;

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

        final entries = <CalendarGridEntry>[];
        for (int year = startDate.year - leadingYears;
            year < startDate.year + trailingYears + 1;
            ++year) {
          entries.add(CalendarGridEntry(
            '$year',
            calendar['$year'] ?? [],
            onClick: onClick != null
                ? onClick!
                : (CalendarGridEntry entry) async {
                    context.read<CustomViewModel>().digests = entry.digests;
                    context.pushNamed('view');
                  },
          ));
        }
        entries.add(CalendarGridEntry(
          'TBA',
          calendar['1970'] ?? [],
          onClick: (CalendarGridEntry entry) async {
            context.read<CustomViewModel>().digests = entry.digests;
            context.pushNamed('view');
          },
        ));

        return CalendarGrid(
          entries,
          selectedLabel: DateFormat('y').format(today),
        );
      },
    );
  }
}

const kPaddingWidthLimit = 2000;
