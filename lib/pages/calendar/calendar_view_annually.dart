import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/calendar_model.dart';
import 'package:espy/pages/calendar/calendar_grid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CalendarViewAnnually extends StatefulWidget {
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
  State<CalendarViewAnnually> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarViewAnnually> {
  @override
  void initState() {
    super.initState();

    leadingYears = widget.leadingYears;
  }

  int leadingYears = 0;

  @override
  Widget build(BuildContext context) {
    final today = widget.startDate ?? DateTime.now().toUtc();

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
            year < today.year + widget.trailingYears + 1;
            ++year) {
          final games = calendar.gamesIn(year);
          entries.add(CalendarGridEntry(
            '$year',
            games
                .map((digest) => LibraryEntry.fromGameDigest(digest))
                .take(4)
                .toList(),
          ));
        }
        entries.add(CalendarGridEntry(
          'TBD',
          calendar
              .gamesIn(1970)
              .map((digest) => LibraryEntry.fromGameDigest(digest))
              .toList(),
        ));

        return CalendarGrid(
          entries,
          onPull: () async {
            if (today.year - leadingYears > 1979) {
              setState(() {
                leadingYears += today.year - leadingYears - 1979 < 14
                    ? today.year - leadingYears - 1979
                    : 14;
              });
            }
          },
          selectedLabel: DateFormat('y').format(today),
        );
      },
    );
  }
}

const kPaddingWidthLimit = 2000;
