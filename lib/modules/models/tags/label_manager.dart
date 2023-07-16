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

    _labelsByCount = _labelToGameIds.entries
        .map((entry) => (entry.key, entry.value.length))
        .toList()
      ..sort((a, b) => b.$2 - a.$2);
  }

  Iterable<String> get all => _labelsByCount.map((e) => e.$1);

  Iterable<String> get nonSingleton =>
      _labelsByCount.where((e) => e.$2 > 1).map((e) => e.$1);

  Iterable<int> gameIds(String label) => _labelToGameIds[label] ?? [];

  int size(String label) => _labelToGameIds[label]?.length ?? 0;

  Iterable<String> filter(Iterable<String> ngrams) {
    return all.where((label) => ngrams.every((ngram) =>
        label.toLowerCase().split(' ').any((word) => word.startsWith(ngram))));
  }

  Iterable<String> filterExact(Iterable<String> ngrams) {
    return all.where((label) => ngrams.every((ngram) =>
        label.toLowerCase().split(' ').any((word) => word == ngram)));
  }

  final Map<String, List<int>> _labelToGameIds = {};
  late List<(String, int)> _labelsByCount = [];
}
