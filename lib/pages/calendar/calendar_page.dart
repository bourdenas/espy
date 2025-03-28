import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/frontpage_model.dart';
import 'package:espy/pages/calendar/calendar_view_annually.dart';
import 'package:espy/pages/calendar/calendar_view_daily.dart';
import 'package:espy/pages/calendar/calendar_view_monthly.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarView calendarView = CalendarView.day;
  int leadingTime = 2;

  void increaseLeading() {
    leadingTime += switch (calendarView) {
      CalendarView.day => 2,
      CalendarView.month => 1,
      CalendarView.year => 14,
    };

    final max = maxLeading();
    leadingTime = leadingTime > max ? max : leadingTime;
  }

  int maxLeading() {
    return switch (calendarView) {
      CalendarView.day => 14,
      CalendarView.month => 5,
      CalendarView.year => DateTime.now().toUtc().year - 1979,
    };
  }

  @override
  Widget build(BuildContext context) {
    final libraryEntries = context
        .watch<FrontpageModel>()
        .frontpage
        .digests
        .map((digest) => LibraryEntry.fromGameDigest(digest));

    final maxLeadingTime = maxLeading();
    return Scaffold(
      appBar: calendarAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => increaseLeading());
        },
        child: switch (calendarView) {
          CalendarView.day =>
            CalendarViewDaily(libraryEntries, leadingWeeks: leadingTime),
          CalendarView.month =>
            CalendarViewMonthly(libraryEntries, leadingYears: leadingTime),
          CalendarView.year => CalendarViewAnnually(leadingYears: leadingTime),
        },
      ),
      floatingActionButton: Row(
        children: [
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: leadingTime < maxLeadingTime
                ? () {
                    setState(() => increaseLeading());
                  }
                : null,
            backgroundColor:
                leadingTime == maxLeadingTime ? Colors.black : null,
            child: Icon(Icons.keyboard_arrow_up),
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: leadingTime < maxLeadingTime
                ? () {
                    setState(() {
                      leadingTime = maxLeadingTime;
                    });
                  }
                : null,
            backgroundColor:
                leadingTime == maxLeadingTime ? Colors.black : null,
            child: Icon(Icons.keyboard_double_arrow_up),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  AppBar calendarAppBar(BuildContext context) {
    return AppBar(
      title: Stack(
        children: [
          Text('Release Calendar'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SegmentedButton<CalendarView>(
                segments: const <ButtonSegment<CalendarView>>[
                  ButtonSegment<CalendarView>(
                    value: CalendarView.day,
                    label: Text('Day'),
                    icon: Icon(Icons.calendar_view_day),
                  ),
                  ButtonSegment<CalendarView>(
                    value: CalendarView.month,
                    label: Text('Month'),
                    icon: Icon(Icons.calendar_view_month),
                  ),
                  ButtonSegment<CalendarView>(
                    value: CalendarView.year,
                    label: Text('Year'),
                    icon: Icon(Icons.calendar_today),
                  ),
                ],
                selected: <CalendarView>{calendarView},
                onSelectionChanged: (Set<CalendarView> newSelection) {
                  setState(() {
                    calendarView = newSelection.first;
                    leadingTime = switch (calendarView) {
                      CalendarView.day => 2,
                      CalendarView.month => 1,
                      CalendarView.year => 18,
                    };
                  });
                },
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.black.withValues(alpha: 0.2),
      elevation: 0.0,
    );
  }
}

enum CalendarView {
  day,
  month,
  year,
}
