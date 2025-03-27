import 'package:espy/modules/models/calendar_model.dart';
import 'package:espy/pages/calendar/calendar_grid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarViewAnnually extends StatelessWidget {
  const CalendarViewAnnually({
    super.key,
    this.startDate,
    this.leadingYears = 25,
    this.trailingYears = 1,
  });

  final DateTime? startDate;
  final int leadingYears;
  final int trailingYears;

  @override
  Widget build(BuildContext context) {
    final today = startDate ?? DateTime.now().toUtc();

    return FutureBuilder(
      future: context.read<CalendarModel>().load(),
      builder: (BuildContext context, AsyncSnapshot<CalendarModel> snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !snapshot.hasData) {
          return Container();
        }
        final calendar = snapshot.data!;

        final entries = <CalendarGridEntry>[];
        for (int year = today.year - leadingYears;
            year < today.year + trailingYears + 1;
            ++year) {
          final games = calendar.gamesIn(year);
          entries.add(CalendarGridEntry(
            '$year',
            games.take(4).toList(),
          ));
        }
        entries.add(CalendarGridEntry(
          'TBD',
          calendar.gamesIn(1970).toList(),
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
