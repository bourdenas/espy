import 'package:espy/modules/filtering/library_filter.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

// Navigable top-level filter in a library view. It restricts visibility of
// the library.
class LibraryFilterModel extends ChangeNotifier {
  LibraryFilter _filter = LibraryFilter();

  LibraryFilter get filter => _filter;

  set filter(LibraryFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void clear() {
    _filter = LibraryFilter();
    notifyListeners();
  }
}

// Filtering refinements that are used for drill-down. They have a less
// permanent nature, e.g. no URL representation.
class RefinementModel extends ChangeNotifier {
  LibraryFilter _refinement = LibraryFilter();

  LibraryFilter get refinement => _refinement;

  set refinement(LibraryFilter filter) {
    _refinement = filter;
    notifyListeners();
  }

  void add(LibraryFilter filter) {
    _refinement = _refinement.add(filter);
    notifyListeners();
  }

  void subtract(LibraryFilter filter) {
    _refinement = _refinement.subtract(filter);
    notifyListeners();
  }

  void clear() {
    _refinement = LibraryFilter();
    notifyListeners();
  }
}
