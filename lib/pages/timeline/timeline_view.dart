import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/widgets/flat_shelve.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:timelines/timelines.dart';

class TimelineView extends StatelessWidget {
  const TimelineView({super.key, this.date});

  final String? date;

  @override
  Widget build(BuildContext context) {
    final shelves = context.watch<FrontpageModel>().games;

    return Timeline.tileBuilder(
      // scrollDirection: Axis.horizontal,
      builder: TimelineTileBuilder.connectedFromStyle(
        connectionDirection: ConnectionDirection.before,
        connectorStyleBuilder: (context, index) {
          return (index == 1)
              ? ConnectorStyle.dashedLine
              : ConnectorStyle.solidLine;
        },
        indicatorStyleBuilder: (context, index) => IndicatorStyle.container,
        // itemExtent: 40.0,
        // contentsAlign: ContentsAlign.basic,
        itemCount: shelves.length,
        contentsBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Timeline Event $index'),
        ),
      ),
    );

    // return ScrollablePositionedList.builder(
    //   itemCount: shelves.length,
    //   initialScrollIndex: startIndex,
    //   itemBuilder: (context, index) {
    //     final (date, games) = shelves[index];
    //     return FlatShelve(
    //       title: DateFormat.yMMMd().format(date),
    //       color: Theme.of(context).colorScheme.onPrimaryContainer,
    //       entries: games.map((digest) => LibraryEntry.fromGameDigest(digest)),
    //     );
    //   },
    // );
  }
}
