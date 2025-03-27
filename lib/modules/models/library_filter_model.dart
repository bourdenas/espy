import 'package:espy/modules/filtering/library_filter.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

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
