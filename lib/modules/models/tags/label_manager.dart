import 'package:espy/modules/documents/library_entry.dart';

class LabelManager {
  LabelManager(
    Iterable<LibraryEntry> entries,
    Iterable<String> Function(LibraryEntry) labelExtractor,
  ) {
    for (final entry in entries) {
      for (final label in labelExtractor(entry)) {
        (_labelToLibraryEntries[label] ??= []).add(entry);
      }
    }

    for (final gameList in _labelToLibraryEntries.values) {
      gameList.sort((a, b) => -a.releaseDate.compareTo(b.releaseDate));
    }

    _labelsByCount = _labelToLibraryEntries.entries
        .map((entry) => (entry.key, entry.value.length))
        .toList()
      ..sort((a, b) => b.$2 - a.$2);
  }

  Iterable<String> get all => _labelsByCount.map((e) => e.$1);

  Iterable<String> get nonSingleton =>
      _labelsByCount.where((e) => e.$2 > 1).map((e) => e.$1);

  Iterable<int> gameIds(String label) => (_labelToLibraryEntries[label] ?? [])
      .map((libraryEntry) => libraryEntry.id);

  Iterable<LibraryEntry> games(String label) =>
      _labelToLibraryEntries[label] ?? [];

  int size(String label) => _labelToLibraryEntries[label]?.length ?? 0;

  Iterable<String> filter(Iterable<String> ngrams) {
    return all.where((label) => ngrams.every((ngram) =>
        label.toLowerCase().split(' ').any((word) => word.startsWith(ngram))));
  }

  Iterable<String> filterExact(Iterable<String> ngrams) {
    return all.where((label) => ngrams.every((ngram) =>
        label.toLowerCase().split(' ').any((word) => word == ngram)));
  }

  final Map<String, List<LibraryEntry>> _labelToLibraryEntries = {};
  late List<(String, int)> _labelsByCount = [];
}
