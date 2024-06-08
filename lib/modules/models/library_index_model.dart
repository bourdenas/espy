import 'dart:collection';

import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class LibraryIndexModel extends ChangeNotifier {
  HashMap<int, LibraryEntry> _gamesById = HashMap();

  HashMap<int, LibraryEntry> get gamesById => _gamesById;
  Iterable<LibraryEntry> get entries => _gamesById.values;
  bool get isNotEmpty => _gamesById.isNotEmpty;

  bool contains(int id) => _gamesById[id] != null;

  LibraryEntry? getEntryById(int id) => _gamesById[id];

  LibraryEntry? getEntryByStringId(String id) {
    final gameId = int.tryParse(id);
    if (gameId == null) {
      return null;
    }

    return getEntryById(gameId);
  }

  void update(Iterable<LibraryEntry> entries) {
    _gamesById = HashMap.fromEntries(entries.map((e) => MapEntry(e.id, e)));
    notifyListeners();
  }
}
