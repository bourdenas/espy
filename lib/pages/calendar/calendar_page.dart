import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/pages/calendar/calendar_view.dart';
import 'package:espy/pages/calendar/calendar_view_monthly.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarViewLevel viewLevel = CalendarViewLevel.dialy;

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
        CalendarViewLevel.dialy => CalendarView(libraryView.entries),
        CalendarViewLevel.monthly => CalendarViewMonthly(libraryView.entries),
        CalendarViewLevel.annual => throw UnimplementedError(),
      },
      floatingActionButton: Row(
        children: [
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: viewLevel == CalendarViewLevel.monthly
                ? () => setState(() {
                      viewLevel = CalendarViewLevel.dialy;
                    })
                : null,
            backgroundColor:
                viewLevel == CalendarViewLevel.dialy ? Colors.black : null,
            child: Icon(Icons.zoom_in),
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: viewLevel == CalendarViewLevel.dialy
                ? () => setState(() {
                      viewLevel = CalendarViewLevel.monthly;
                    })
                : null,
            backgroundColor:
                viewLevel == CalendarViewLevel.monthly ? Colors.black : null,
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
  dialy,
  monthly,
  annual,
}
