import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/library/library_grid_card.dart';
import 'package:flutter/material.dart';

class CalendarGridEntry {
  static const CalendarGridEntry empty = CalendarGridEntry(null, []);

  const CalendarGridEntry(this.label, this.libraryEntries);

  final String? label;
  final List<LibraryEntry> libraryEntries;
}

class CalendarGrid extends StatelessWidget {
  const CalendarGrid(
    this.entries, {
    super.key,
    required this.onPull,
    this.gridCount = 7,
    this.selectedLabel,
  });

  final List<CalendarGridEntry> entries;
  final Future<void> Function() onPull;
  final int gridCount;
  final String? selectedLabel;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onPull,
      child: CustomScrollView(
        primary: true,
        shrinkWrap: true,
        slivers: [
          SliverCrossAxisGroup(
            slivers: [
              if (MediaQuery.of(context).size.width > kPaddingWidthLimit)
                SliverToBoxAdapter(child: Container()),
              SliverCrossAxisExpanded(
                flex: 8,
                sliver: SliverConstrainedCrossAxis(
                  maxExtent: 1800,
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: 10.0,
                      crossAxisSpacing: 10.0,
                      childAspectRatio:
                          AppConfigModel.gridCardContraints.cardAspectRatio,
                      crossAxisCount: gridCount,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final entry = entries[index];
                        return Container(
                          alignment: Alignment.topLeft,
                          color: entry.label == selectedLabel
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: calendarTile(entry),
                        );
                      },
                      childCount: entries.length,
                    ),
                  ),
                ),
              ),
              if (MediaQuery.of(context).size.width > kPaddingWidthLimit)
                SliverToBoxAdapter(child: Container()),
            ],
          ),
        ],
      ),
    );
  }

  Widget calendarTile(CalendarGridEntry entry) {
    if (entry.libraryEntries.isNotEmpty) {
      return LibraryGridCard(
        entry.libraryEntries.first,
        overlays: [
          Positioned(
            top: -1,
            left: -1,
            child: Container(
              color: Color.fromRGBO(0, 0, 0, .7),
              padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Text(entry.label!),
            ),
          ),
        ],
      );
    }
    if (entry.label != null) {
      return Padding(
        padding: const EdgeInsets.all(7),
        child: Container(
          color: Color.fromRGBO(0, 0, 0, .7),
          padding: EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Text(entry.label!),
        ),
      );
    }
    return Container();
  }
}

const kPaddingWidthLimit = 2000;
