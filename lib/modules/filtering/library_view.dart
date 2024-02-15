import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';

/// NOTE: THIS MIGHT NEED TO BE PART OF THE LibraryViewModel instead.
/// Represents a view of the library after a LibraryFilter is applied.
class LibraryView {
  LibraryView(this._libraryEntries);

  final List<LibraryEntry> _libraryEntries;

  Iterable<LibraryEntry> get all => _libraryEntries;
  int get length => _libraryEntries.length;

  void sort(LibraryOrdering ordering) {
    switch (ordering) {
      case LibraryOrdering.release:
        _libraryEntries.sort((a, b) => -a.releaseDate.compareTo(b.releaseDate));
        break;
      case LibraryOrdering.rating:
        _libraryEntries.sort((a, b) => -a.metacritic.compareTo(b.metacritic));
        break;
      case LibraryOrdering.title:
        _libraryEntries.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
  }

  List<(String, List<LibraryEntry>)> group(LibraryGrouping grouping) {
    switch (grouping) {
      case LibraryGrouping.none:
        return [('', _libraryEntries)];
      case LibraryGrouping.year:
        return _groupBy(
          _libraryEntries,
          (e) => [
            '${DateTime.fromMillisecondsSinceEpoch(e.releaseDate * 1000).year}'
          ],
          (a, b) => -a.compareTo(b),
        );
      case LibraryGrouping.genre:
        return _groupBy(
          _libraryEntries,
          (e) => e.digest.genres,
        );
      case LibraryGrouping.genreTag:
        return _groupBy(
          _libraryEntries,
          // TODO: Fix user genre tag grouping.
          (e) => e.digest.genres,
        );
      case LibraryGrouping.rating:
        return _groupBy(
          _libraryEntries,
          (e) => [
            switch (e.digest.scores.metacritic) {
              int x when x >= 95 => 'Masterpiece',
              int x when x >= 90 => 'Excellent',
              int x when x >= 80 => 'Great',
              int x when x >= 70 => 'Good',
              int x when x >= 60 => 'Mixed',
              int() => 'Bad',
              null => 'Unknown',
            }
          ],
          (a, b) => ratingTitles.indexOf(a).compareTo(ratingTitles.indexOf(b)),
        );
    }
  }

  static const ratingTitles = [
    'Masterpiece',
    'Excellent',
    'Great',
    'Good',
    'Mixed',
    'Bad',
    'Unknown',
  ];

  List<(String, List<LibraryEntry>)> _groupBy(Iterable<LibraryEntry> entries,
      Iterable<String> Function(LibraryEntry) keysExtractor,
      [int Function(String, String)? keyCompare]) {
    var groups = <String, List<LibraryEntry>>{};
    for (final entry in entries) {
      final keys = keysExtractor(entry);
      if (keys.isEmpty) {
        (groups['🚫'] ??= []).add(entry);
      }
      for (final key in keys) {
        (groups[key] ??= []).add(entry);
      }
    }

    if (keyCompare != null) {
      final keys = groups.keys.toList()..sort(keyCompare);
      return keys
          .map((key) => (key, groups[key]))
          .whereType<(String, List<LibraryEntry>)>()
          .toList();
    } else {
      return groups.entries.map((e) => (e.key, e.value)).toList()
        ..sort((a, b) => -a.$2.length.compareTo(b.$2.length));
    }
  }
}
