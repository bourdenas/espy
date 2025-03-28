import 'package:espy/modules/models/calendar_model.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/modules/models/years_model.dart';
import 'package:espy/pages/calendar/calendar_grid.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
          entries.add(CalendarGridEntry(
            '$year',
            calendar.gamesIn(year),
            onClick: (CalendarGridEntry entry) async {
              final games = await context.read<YearsModel>().gamesIn('$year');
              if (context.mounted) {
                context.read<CustomViewModel>().digests = games.releases;
                context.pushNamed('view');
              }
            },
          ));
        }
        entries.add(CalendarGridEntry(
          'TBD',
          calendar.gamesIn(1970).toList(),
          onClick: (CalendarGridEntry entry) async {
            final games = await context.read<YearsModel>().gamesIn('1970');
            if (context.mounted) {
              context.read<CustomViewModel>().digests = games.releases;
              context.pushNamed('view');
            }
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
