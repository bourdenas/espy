import 'dart:collection';

import 'package:espy/modules/documents/library_entry.dart';

class LabelManager {
  LabelManager(Iterable<LibraryEntry> entries,
      [Iterable<String> Function(LibraryEntry)? labelExtractor]) {
    if (labelExtractor == null) return;

    for (final entry in entries) {
      for (final label in labelExtractor(entry)) {
        (_labelToGameIds[label] ??= []).add(entry.id);
      }
    }
  }

  UnmodifiableListView<String> get all =>
      UnmodifiableListView(_labelToGameIds.keys.toList()..sort());

  UnmodifiableListView<String> get nonSingleton =>
      UnmodifiableListView(_labelToGameIds.entries
          .where((entry) => entry.value.length > 1)
          .map((entry) => entry.key)
          .toList()
        ..sort());

  Iterable<int> gameIds(String label) => _labelToGameIds[label] ?? [];

  int size(String label) => _labelToGameIds[label]?.length ?? 0;

  Iterable<String> filter(Iterable<String> ngrams) {
    return nonSingleton.where((label) => ngrams.every((ngram) =>
        label.toLowerCase().split(' ').any((word) => word.startsWith(ngram))));
  }

  Iterable<String> filterExact(Iterable<String> ngrams) {
    return nonSingleton.where((label) => ngrams.every((ngram) =>
        label.toLowerCase().split(' ').any((word) => word == ngram)));
  }

  final Map<String, List<int>> _labelToGameIds = {};
}
