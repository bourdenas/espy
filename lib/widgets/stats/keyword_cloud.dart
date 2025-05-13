import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/app_config_model.dart';
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
    // Get a copy of the currect filter.
    final filter = context.watch<FilterModel>().filter.add(LibraryFilter());
    final selectedKeyword = filter.keyword;

    Map<String, int> kwGroupsPops = {};
    Map<String, int> kwPops = {};
    final model = FilterModel.create(filter, context.read<AppConfigModel>());
    for (final entry in model.processLibraryEntries(widget.libraryEntries)) {
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
              mapWidth: 460,
              mapHeight: 250,
              minTextSize: 12,
              maxTextSize: 42,
            ),
            onClick: (String word) {
              final filter = LibraryFilter(keyword: word);
              if (context.read<FilterModel>().filter.keyword != word) {
                context.read<FilterModel>().add(filter);
              } else {
                context.read<FilterModel>().subtract(filter);
              }
            },
          )
        : Container();
  }
}

const unknownLabel = 'None';
