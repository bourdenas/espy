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
    final releases = context.read<TimelineModel>().releases;

    var startIndex = 0;
    for (final release in releases) {
      if (release.date.compareTo(start) > 0) {
        break;
      }
      ++startIndex;
    }

    return ScrollablePositionedList.builder(
      itemCount: releases.length,
      initialScrollIndex: startIndex,
      itemBuilder: (context, index) {
        final release = releases[index];
        return FlatShelve(
          title: DateFormat.yMMMd().format(release.date),
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          entries: release.games
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
        );
      },
    );
  }
}
