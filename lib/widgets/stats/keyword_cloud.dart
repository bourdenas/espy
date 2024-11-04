import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/keyword_mapping.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:word_cloud/word_cloud.dart';

class KeywordCloud extends StatelessWidget {
  const KeywordCloud(this.libraryEntries, {super.key});

  final Iterable<LibraryEntry> libraryEntries;

  @override
  Widget build(BuildContext context) {
    final refinement = context.watch<RefinementModel>().refinement;

    Map<String, int> kwGroupsPops = {};
    Map<String, int> kwPops = {};
    for (final entry in libraryEntries.where((e) => refinement.pass(e))) {
      final groups = <String>{};
      for (final kw in entry.digest.keywords) {
        groups.add(Keywords.groupOfKeyword(kw) ?? unknownLabel);
        kwPops[kw] = (kwPops[kw] ?? 0) + 1;
      }
      for (final group in groups) {
        kwGroupsPops[group] = (kwGroupsPops[group] ?? 0) + 1;
      }
    }

    WordCloudData wcdata = WordCloudData(
        data: kwPops.entries
            .map((entry) => {'word': entry.key, 'value': entry.value})
            .toList());

    return WordCloudView(
      data: wcdata,
      mapcolor: Theme.of(context).colorScheme.surface,
      mapwidth: 500,
      mapheight: 250,
      maxtextsize: 38,
      mintextsize: 10,
      shape: WordCloudEllipse(majoraxis: 250, minoraxis: 125),
      colorlist: const [
        Colors.white,
        Colors.redAccent,
        Colors.green,
        Colors.blue,
        Colors.amber,
      ],
    );
  }
}

const unknownLabel = 'None';
