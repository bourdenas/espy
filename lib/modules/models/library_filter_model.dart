import 'package:espy/modules/filtering/library_filter.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class LibraryFilterModel extends ChangeNotifier {
  final List<LibraryFilter> _filterStack = [];

  LibraryFilter get filter =>
      _filterStack.isNotEmpty ? _filterStack.last : LibraryFilter();

  set filter(LibraryFilter filter) {
    _filterStack.clear();
    _filterStack.add(filter);
    notifyListeners();
  }

  void updateFilter(LibraryFilter filter) {
    _filterStack.add(filter);
    notifyListeners();
  }

  void pop() {
    _filterStack.removeLast();
    notifyListeners();
  }
}
