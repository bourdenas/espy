import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/calendar/calendar_view_month.dart';
import 'package:espy/pages/library/library_entries_view.dart';
import 'package:espy/pages/timeline/timeline_view.dart';
import 'package:espy/widgets/stats/filter_side_pane.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage(this.libraryEntries, {super.key, required this.title});

  final Iterable<LibraryEntry> libraryEntries;
  final String title;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    final filteredEntries = context
        .watch<FilterModel>()
        .processLibraryEntries(widget.libraryEntries);

    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: Scaffold(
                appBar: libraryAppBar(context, filteredEntries.length),
                body: libraryBody(context, filteredEntries),
              ),
            ),
            // Add some space for the side pane.
            SizedBox(
              width: context.watch<AppConfigModel>().showBottomSheet ? 500 : 40,
            ),
          ],
        ),
        FilterSidePane(widget.libraryEntries),
      ],
    );
  }

  Widget libraryBody(
    BuildContext context,
    Iterable<LibraryEntry> libraryEntries,
  ) {
    final libraryView = context.watch<AppConfigModel>().libraryViewMode.value;

    return Column(
      children: [
        Expanded(
          child: switch (libraryView) {
            LibraryViewMode.flat => CustomScrollView(
                primary: true,
                shrinkWrap: true,
                slivers: [
                  LibraryEntriesView(libraryEntries),
                ],
              ),
            LibraryViewMode.month => CalendarViewMonth(
                libraryEntries.map((e) => e.digest),
                startDate: DateTime.now(),
                yearsBack: 45,
              ),
            LibraryViewMode.year => TimelineView(libraryEntries, libraryView),
          },
        ),
      ],
    );
  }

  AppBar libraryAppBar(BuildContext context, int libraryViewLength) {
    final libraryView = context.watch<AppConfigModel>().libraryViewMode;

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
      title: Stack(
        children: [
          Text(widget.title),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SegmentedButton<LibraryViewMode>(
                segments: const <ButtonSegment<LibraryViewMode>>[
                  ButtonSegment<LibraryViewMode>(
                    value: LibraryViewMode.flat,
                    label: Text('Flat'),
                    icon: Icon(Icons.view_stream),
                  ),
                  ButtonSegment<LibraryViewMode>(
                    value: LibraryViewMode.month,
                    label: Text('Month'),
                    icon: Icon(Icons.calendar_view_month),
                  ),
                  ButtonSegment<LibraryViewMode>(
                    value: LibraryViewMode.year,
                    label: Text('Year'),
                    icon: Icon(Icons.calendar_month),
                  ),
                ],
                selected: <LibraryViewMode>{libraryView.value},
                onSelectionChanged: (Set<LibraryViewMode> newSelection) {
                  setState(() {
                    libraryView.value = newSelection.first;
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
