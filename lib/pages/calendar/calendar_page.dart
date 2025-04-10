import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/modules/models/frontpage_model.dart';
import 'package:espy/modules/models/years_model.dart';
import 'package:espy/pages/calendar/calendar_grid_entry.dart';
import 'package:espy/pages/calendar/calendar_view_year.dart';
import 'package:espy/pages/calendar/calendar_view_day.dart';
import 'package:espy/pages/calendar/calendar_view_month.dart';
import 'package:espy/widgets/stats/refinements_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      CalendarView.year => 0,
    };

    final max = maxLeading();
    leadingTime = leadingTime > max ? max : leadingTime;
  }

  int maxLeading() {
    return switch (calendarView) {
      CalendarView.day => 14,
      CalendarView.month => 1,
      CalendarView.year => 0,
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
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              setState(() => increaseLeading());
            },
            child: Column(
              children: [
                Expanded(
                  child: switch (calendarView) {
                    // TODO: Uplevel retrieval for entries at this level.
                    CalendarView.day => CalendarViewDay(
                        libraryEntries,
                        leadingWeeks: 17,
                        trailingWeeks: leadingTime,
                      ),
                    CalendarView.month => CalendarViewMonth(
                        yearsForward: leadingTime,
                      ),
                    CalendarView.year => CalendarViewYear(
                        onClick: (CalendarGridEntry entry) async {
                          final games = await context
                              .read<YearsModel>()
                              .gamesIn('${entry.digests.first.releaseYear}');
                          if (context.mounted) {
                            context.read<CustomViewModel>().digests =
                                games.releases;
                            context.pushNamed('view');
                          }
                        },
                      ),
                  },
                ),
                SizedBox(height: 52),
              ],
            ),
          ),
          RefinementsBottomSheet(libraryEntries),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: leadingTime < maxLeadingTime
            ? () {
                setState(() => increaseLeading());
              }
            : null,
        backgroundColor: leadingTime == maxLeadingTime ? Colors.black : null,
        child: Icon(Icons.keyboard_arrow_up),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
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
                      CalendarView.month => 0,
                      CalendarView.year => 0,
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
