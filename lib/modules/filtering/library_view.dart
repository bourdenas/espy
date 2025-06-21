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
        _libraryEntries.sort((a, b) => -a.releaseDate.compareTo(b.releaseDate)),
      LibraryOrdering.rating =>
        _libraryEntries.sort((a, b) => -a.espyScore.compareTo(b.espyScore)),
      LibraryOrdering.popularity =>
        _libraryEntries.sort((a, b) => -a.prominence.compareTo(b.prominence)),
    };
  }
}
