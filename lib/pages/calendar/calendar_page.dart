import 'package:espy/modules/documents/frontpage.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/calendar_model.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/modules/models/frontpage_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/years_model.dart';
import 'package:espy/pages/calendar/calendar_grid_entry.dart';
import 'package:espy/pages/calendar/calendar_view_year.dart';
import 'package:espy/pages/calendar/calendar_view_day.dart';
import 'package:espy/pages/calendar/calendar_view_month.dart';
import 'package:espy/widgets/stats/filter_side_pane.dart';
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

  Future<List<GameDigest>> recentWeeks(Frontpage frontpage) async {
    return frontpage.digests;
  }

  Future<List<GameDigest>> recentYears(YearsModel yearsModel) async {
    final today = DateTime.now().toUtc();
    final yearsBack = 3;
    final allYears = await yearsModel
        .getYears(List.generate(yearsBack + 1, (i) => '${today.year - i}'));

    return allYears.map((year) => year.releases).expand((e) => e).toList();
  }

  Future<List<GameDigest>> allYears(CalendarModel calendarModel) async {
    return (await calendarModel.calendar).values.expand((e) => e).toList();
  }

  @override
  Widget build(BuildContext context) {
    final maxLeadingTime = maxLeading();

    return FutureBuilder(
      future: switch (calendarView) {
        CalendarView.day =>
          recentWeeks(context.watch<FrontpageModel>().frontpage),
        CalendarView.month => recentYears(context.read<YearsModel>()),
        CalendarView.year => allYears(context.read<CalendarModel>()),
      },
      builder: (context, AsyncSnapshot<List<GameDigest>> snapshot) {
        final games = (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData)
            ? snapshot.data!
            : <GameDigest>[];
        final shownGames = context.watch<FilterModel>().process(games);

        return Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: Scaffold(
                    appBar: calendarAppBar(context),
                    body: RefreshIndicator(
                      onRefresh: () async {
                        setState(() => increaseLeading());
                      },
                      child: switch (calendarView) {
                        CalendarView.day => CalendarViewDay(
                            shownGames,
                            leadingWeeks: 17,
                            trailingWeeks: leadingTime,
                          ),
                        CalendarView.month => CalendarViewMonth(shownGames),
                        CalendarView.year => CalendarViewYear(
                            shownGames,
                            startYear: DateTime.now().toUtc().year + 1,
                            endYear: 1979,
                            onClick: (CalendarGridEntry entry) async {
                              final games = await context
                                  .read<YearsModel>()
                                  .gamesIn(
                                      '${entry.digests.first.releaseYear}');
                              if (context.mounted) {
                                context.read<CustomViewModel>().digests =
                                    games.releases;
                                context.pushNamed('view', pathParameters: {
                                  'title': '${entry.digests.first.releaseYear}'
                                });
                              }
                            },
                          ),
                      },
                    ),
                    floatingActionButton: FloatingActionButton(
                      onPressed: leadingTime < maxLeadingTime
                          ? () {
                              setState(() => increaseLeading());
                            }
                          : null,
                      backgroundColor:
                          leadingTime == maxLeadingTime ? Colors.black : null,
                      child: Icon(Icons.keyboard_arrow_up),
                    ),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.startFloat,
                  ),
                ),
                // Add some space for the side pane.
                SizedBox(
                  width: context.watch<AppConfigModel>().showBottomSheet
                      ? 500
                      : 40,
                ),
              ],
            ),
            FilterSidePane(
              games.map((digest) => LibraryEntry.fromGameDigest(digest)),
            ),
          ],
        );
      },
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
