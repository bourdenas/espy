import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/widgets/flat_shelve.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TimelineShelves extends StatelessWidget {
  const TimelineShelves({super.key, this.date});

  final String? date;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.fromMillisecondsSinceEpoch(int.parse(date!))
        .subtract(const Duration(days: 1));
    final shelves = context.read<TimelineModel>().games;

    var startIndex = 0;
    for (final (release, _) in shelves) {
      if (release.compareTo(start) > 0) {
        break;
      }
      ++startIndex;
    }

    return ScrollablePositionedList.builder(
      itemCount: shelves.length,
      initialScrollIndex: startIndex,
      itemBuilder: (context, index) {
        final (date, games) = shelves[index];
        return FlatShelve(
          title: DateFormat.yMMMd().format(date),
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          entries: games.map((digest) => LibraryEntry.fromGameDigest(digest)),
        );
      },
    );
  }
}
