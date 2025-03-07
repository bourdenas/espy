import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/pages/calendar/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key, this.entries});

  final Iterable<LibraryEntry>? entries;

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
      body: CalendarView(libraryView.entries),
    );
  }

  AppBar calendarAppBar(
    BuildContext context,
    AppConfigModel appConfig,
    int libraryViewLength,
  ) {
    return AppBar(
      leading: badges.Badge(
        badgeContent: Text(
          '$libraryViewLength',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        badgeStyle: badges.BadgeStyle(
          shape: badges.BadgeShape.circle,
          badgeColor: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.all(8),
        ),
        position: badges.BadgePosition.center(),
        child: Container(),
      ),
      title: Text('Release Calendar'),
      backgroundColor: Colors.black.withOpacity(0.6),
      elevation: 0.0,
    );
  }
}
