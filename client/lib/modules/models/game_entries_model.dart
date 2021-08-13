import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/library_filters_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class GameEntriesModel extends ChangeNotifier {
  List<LibraryEntry> _entries = [];
  LibraryFilter _filter = LibraryFilter();

  Iterable<LibraryEntry> get games => _entries.where((e) => _filter.apply(e));

  void update(List<LibraryEntry> entries, LibraryFilter filter) {
    _entries = entries;
    _filter = filter;
    notifyListeners();
  }

  LibraryEntry? getEntryById(String id) {
    final gameId = int.tryParse(id);
    if (gameId == null) {
      return null;
    }

    for (final entry in _entries) {
      if (entry.id == gameId) {
        return entry;
      }
    }
    return null;
  }
}
