import 'package:espy/modules/filtering/library_filter.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class LibraryFilterModel extends ChangeNotifier {
  LibraryFilter _filter = LibraryFilter();

  LibraryFilter get filter => _filter;

  set filter(LibraryFilter filter) {
    _filter = filter;
    notifyListeners();
  }
}
