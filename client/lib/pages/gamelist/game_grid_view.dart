import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/pages/search/search_results.dart';
import 'package:espy/widgets/tiles/tile_group.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameGridView extends StatelessWidget {
  const GameGridView({
    Key? key,
    required this.entries,
  }) : super(key: key);

  final List<LibraryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<AppConfigModel>().groupBy.value == GroupBy.YEAR
        ? groupBy(
            entries,
            (e) =>
                '${DateTime.fromMillisecondsSinceEpoch(e.releaseDate * 1000).year}')
        : {'': entries};
    final keys = groups.keys.toList()..sort();

    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        if (groups.length == 1)
          GameSearchResults(
            entries: entries,
            cardWidth: _maxCardWidth,
            cardAspectRatio: _cardAspectRation,
          )
        else ...[
          for (final key in keys.reversed)
            TileGroup(
              title: '$key',
              color: Colors.grey,
              entries: groups[key]!,
              cardWidth: _maxCardWidth,
              cardAspectRatio: _cardAspectRation,
            ),
        ],
      ],
    );
  }

  static const _maxCardWidth = 250.0;
  static const _cardAspectRation = .75;
}

Map<String, List<LibraryEntry>> groupBy(
    Iterable<LibraryEntry> entries, String Function(LibraryEntry) key) {
  var groups = <String, List<LibraryEntry>>{};
  for (final entry in entries) {
    (groups[key(entry)] ??= []).add(entry);
  }
  return groups;
}
