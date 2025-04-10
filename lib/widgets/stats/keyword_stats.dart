import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/keyword_mapping.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/stats/legend.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class KeywordStats extends StatefulWidget {
  const KeywordStats(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  State<KeywordStats> createState() => _KeywordStatsState();
}

class _KeywordStatsState extends State<KeywordStats> {
  String? selectedGroup;
  String? selectedKeyword;
  Map<String, int> kwGroupsPops = {};
  Map<String, int> kwPops = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final refinement = context.watch<RefinementModel>().refinement;
    selectedKeyword = refinement.keyword;

    // Build Keyword histograms.
    kwGroupsPops.clear();
    kwPops.clear();
    int unknownPops = 0;
    for (final entry
        in widget.libraryEntries.where((e) => refinement.passLibraryEntry(e))) {
      if (entry.digest.keywords.isEmpty) {
        unknownPops += 1;
      }
      final groups = <String>{};
      for (final kw in entry.digest.keywords) {
        groups.add(Keywords.groupOfKeyword(kw) ?? unknownLabel);
        kwPops[kw] = (kwPops[kw] ?? 0) + 1;
      }
      for (final group in groups) {
        kwGroupsPops[group] = (kwGroupsPops[group] ?? 0) + 1;
      }
    }
    kwGroupsPops[unknownLabel] = unknownPops;
    kwPops[unknownLabel] = unknownPops;

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          if (selectedGroup == null || selectedGroup == unknownLabel)
            keywordGroups(context)
          else
            keywordsInGroup(context),
        ],
      ),
    );
  }

  Widget keywordGroups(BuildContext context) {
    return Legend(
      Keywords.groups.toList() + [unknownLabel],
      itemPops: kwGroupsPops,
      selectedItem: selectedGroup,
      onItemTap: (selectedItem) => setState(() {
        selectedGroup = selectedItem;
      }),
    );
  }

  Widget keywordsInGroup(BuildContext context) {
    final keywordsInGroup = Keywords.keywordsInGroup(selectedGroup!);

    return Legend(
      width: 200,
      keywordsInGroup ?? ['#ERROR'],
      itemPops: keywordsInGroup?.first != unknownLabel
          ? kwPops
          : {unknownLabel: kwPops[unknownLabel] ?? 0},
      selectedItem: selectedKeyword,
      onItemTap: (selectedItem) {
        final filter = LibraryFilter(keyword: selectedItem);
        if (selectedKeyword != selectedItem) {
          context.read<RefinementModel>().add(filter);
        } else {
          context.read<RefinementModel>().subtract(filter);
        }
      },
      backLabel: selectedGroup,
      onBack: () {
        setState(() {
          selectedGroup = null;
        });
        context.read<RefinementModel>().subtract(
              LibraryFilter(
                keyword: selectedKeyword,
              ),
            );
      },
    );
  }
}

const unknownLabel = 'None';
