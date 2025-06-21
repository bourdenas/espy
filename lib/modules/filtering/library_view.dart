import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';

class LibraryView {
  List<LibraryEntry> get entries => _libraryEntries;
  int get length => _libraryEntries.length;

  final List<LibraryEntry> _libraryEntries;
  final LibraryOrdering ordering;

  LibraryView(
    this._libraryEntries, {
    this.ordering = LibraryOrdering.release,
  }) {
    final _ = switch (ordering) {
      LibraryOrdering.release =>
        _libraryEntries.sort((l, r) => r.releaseDate.compareTo(l.releaseDate)),
      LibraryOrdering.rating => _libraryEntries.sort((l, r) =>
          -(l.scores.espyScore?.compareTo(r.scores.espyScore ?? 0) ?? -1)),
      LibraryOrdering.popularity => _libraryEntries
          .sort((l, r) => r.digest.prominence.compareTo(l.digest.prominence)),
    };
  }
}
