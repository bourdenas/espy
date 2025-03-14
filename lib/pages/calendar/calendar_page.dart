import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/pages/calendar/annual_view.dart';
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
  CalendarViewLevel viewLevel = CalendarViewLevel.daily;

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigModel>();
    final filter = context.watch<LibraryFilterModel>().filter;
    final releases = context.watch<TimelineModel>().releases;
    final libraryView = LibraryViewModel.custom(
      appConfig,
      releases
          .map((event) => event.games)
          .expand((e) => e)
          .map((digest) => LibraryEntry.fromGameDigest(digest)),
      filter: filter,
    );

    return Scaffold(
      appBar: calendarAppBar(context, appConfig, libraryView.length),
      body: switch (viewLevel) {
        CalendarViewLevel.daily => CalendarViewDaily(libraryView.entries),
        CalendarViewLevel.monthly => CalendarViewMonthly(libraryView.entries),
        CalendarViewLevel.annual => AnnualView(),
      },
      floatingActionButton: Row(
        children: [
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: viewLevel != CalendarViewLevel.daily
                ? () => setState(() {
                      viewLevel = viewLevel == CalendarViewLevel.annual
                          ? CalendarViewLevel.monthly
                          : CalendarViewLevel.daily;
                    })
                : null,
            backgroundColor:
                viewLevel == CalendarViewLevel.daily ? Colors.black : null,
            child: Icon(Icons.zoom_in),
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: viewLevel != CalendarViewLevel.annual
                ? () => setState(() {
                      viewLevel = viewLevel == CalendarViewLevel.daily
                          ? CalendarViewLevel.monthly
                          : CalendarViewLevel.annual;
                    })
                : null,
            backgroundColor:
                viewLevel == CalendarViewLevel.annual ? Colors.black : null,
            child: Icon(Icons.zoom_out),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  AppBar calendarAppBar(
    BuildContext context,
    AppConfigModel appConfig,
    int libraryViewLength,
  ) {
    return AppBar(
      title: Text('Release Calendar'),
      backgroundColor: Colors.black.withValues(alpha: 0.2),
      elevation: 0.0,
    );
  }
}

enum CalendarViewLevel {
  daily,
  monthly,
  annual,
}
