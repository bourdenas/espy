import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/keyword_mapping.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/stats/word_cloud.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class KeywordCloud extends StatefulWidget {
  const KeywordCloud(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  State<KeywordCloud> createState() => _KeywordCloudState();
}

class _KeywordCloudState extends State<KeywordCloud> {
  @override
  Widget build(BuildContext context) {
    final refinement =
        context.watch<RefinementModel>().refinement.add(LibraryFilter());
    final selectedKeyword = refinement.keyword;

    Map<String, int> kwGroupsPops = {};
    Map<String, int> kwPops = {};
    for (final entry
        in widget.libraryEntries.where((e) => refinement.pass(e))) {
      final groups = <String>{};
      for (final kw in entry.digest.keywords) {
        if (kw == 'co-op' || kw == 'PvP') continue;

        groups.add(Keywords.groupOfKeyword(kw) ?? unknownLabel);
        kwPops[kw] = (kwPops[kw] ?? 0) + 1;
      }
      for (final group in groups) {
        kwGroupsPops[group] = (kwGroupsPops[group] ?? 0) + 1;
      }
    }

    return kwPops.isNotEmpty
        ? WordCloud(
            words: kwPops.entries
                .map((entry) => WordSpec(
                      entry.key,
                      entry.value.toDouble(),
                      color: selectedKeyword == entry.key
                          ? Colors.white
                          : keywordsPalette[Keywords.groupOfKeyword(entry.key)],
                    ))
                .toList(),
            config: WordCloudConfig(
              attempts: 30,
              mapWidth: 500,
              mapHeight: 250,
              minTextSize: 12,
              maxTextSize: 42,
            ),
            onClick: (String word) {
              final filter = LibraryFilter(keyword: word);
              if (context.read<RefinementModel>().refinement.keyword != word) {
                context.read<RefinementModel>().add(filter);
              } else {
                context.read<RefinementModel>().subtract(filter);
              }
            },
          )
        : Container();
  }
}

const unknownLabel = 'None';
