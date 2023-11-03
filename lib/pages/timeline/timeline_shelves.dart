import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/frontpage_model.dart';
import 'package:espy/widgets/flat_shelve.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TimelineShelves extends StatelessWidget {
  const TimelineShelves({Key? key, this.date}) : super(key: key);

  final String? date;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.fromMillisecondsSinceEpoch(int.parse(date!))
        .subtract(const Duration(days: 1));

    final shelves = <(String, List<GameDigest>)>[];
    context.read<FrontpageModel>().games.forEach((date, games) {
      shelves.add((date, games));
    });
    shelves.sort((a, b) => DateFormat.yMMMd()
        .parse(a.$1)
        .compareTo(DateFormat.yMMMd().parse(b.$1)));

    var startIndex = 0;
    for (final (release, _) in shelves) {
      if (DateFormat.yMMMd().parse(release).compareTo(start) > 0) {
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
          title: date,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          entries: games.map((digest) => LibraryEntry.fromGameDigest(digest)),
        );
      },
    );
  }
}
