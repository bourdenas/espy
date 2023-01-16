import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/widgets/library/library_group.dart';
import 'package:flutter/material.dart';

class GameGridView extends StatelessWidget {
  const GameGridView({
    Key? key,
    required this.entries,
  }) : super(key: key);

  final List<LibraryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final groupByYear = groupBy(entries,
        (e) => DateTime.fromMillisecondsSinceEpoch(e.releaseDate * 1000).year);
    var years = groupByYear.keys.toList();
    years.sort();

    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        for (final year in years.reversed)
          LibraryGroup(
            title: '$year',
            color: Colors.grey,
            entries: groupByYear[year]!,
            cardWidth: _maxCardWidth,
            cardAspectRatio: _cardAspectRation,
          ),
      ],
    );
  }

  static const _maxCardWidth = 250.0;
  static const _cardAspectRation = .75;
}

Map<T, List<LibraryEntry>> groupBy<T>(
    Iterable<LibraryEntry> entries, T Function(LibraryEntry) key) {
  var groups = <T, List<LibraryEntry>>{};
  for (final entry in entries) {
    (groups[key(entry)] ??= []).add(entry);
  }
  return groups;
}
