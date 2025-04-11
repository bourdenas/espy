import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/scores.dart';
import 'package:espy/modules/models/app_config_model.dart';

class LibraryView {
  Iterable<LibraryEntry> get entries => _libraryEntries;
  int get length => _libraryEntries.length;

  late List<LibraryEntry> _libraryEntries;
  final AppConfigModel _config;

  LibraryView(Iterable<LibraryEntry> libraryEntries, this._config) {
    _libraryEntries = libraryEntries.toList();

    final _ = switch (_config.libraryOrdering.value) {
      LibraryOrdering.release =>
        _libraryEntries.sort((a, b) => -a.releaseDate.compareTo(b.releaseDate)),
      LibraryOrdering.rating =>
        _libraryEntries.sort((a, b) => -a.espyScore.compareTo(b.espyScore)),
      LibraryOrdering.popularity => _libraryEntries.sort((a, b) {
          final cmp = -a.popularity.compareTo(b.popularity);
          if (cmp != 0) return cmp;
          return -a.hype.compareTo(b.hype);
        }),
    };
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
          (e) => e.digest.espyGenres.toSet(),
        );
      case LibraryGrouping.keywords:
        return _groupBy(
          _libraryEntries,
          (e) => e.digest.keywords.toSet(),
        );
      case LibraryGrouping.rating:
        return _groupBy(
          _libraryEntries,
          (e) => [e.digest.scores.title],
          (a, b) => scoreTitles.indexOf(a).compareTo(scoreTitles.indexOf(b)),
        );
    }
  }

  List<(String, List<LibraryEntry>)> _groupBy(Iterable<LibraryEntry> entries,
      Iterable<String> Function(LibraryEntry) keysExtractor,
      [int Function(String, String)? keyCompare]) {
    var groups = <String, List<LibraryEntry>>{};
    for (final entry in entries) {
      final keys = keysExtractor(entry);
      if (keys.isEmpty) {
        (groups['Unassigned'] ??= []).add(entry);
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
