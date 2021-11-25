import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/routing/library_filter.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class GameEntriesModel extends ChangeNotifier {
  List<LibraryEntry> _entries = [];

  void update(List<LibraryEntry> entries) {
    _entries = entries;
    notifyListeners();
  }

  Iterable<LibraryEntry> getEntries(LibraryFilter? filter) =>
      _entries.where((e) => filter != null ? filter.apply(e) : true);

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
