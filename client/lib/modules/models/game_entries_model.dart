import 'dart:collection';

import 'package:espy/modules/models/library_filters_model.dart';
import 'package:espy/proto/library.pb.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class GameEntriesModel extends ChangeNotifier {
  List<GameEntry> _entries = [];
  LibraryFilter _filter = LibraryFilter();

  UnmodifiableListView<GameEntry> get games =>
      UnmodifiableListView(_entries.where((e) => _filter.apply(e)));

  void update(Library library, LibraryFilter filter) {
    _entries = library.entry;
    _filter = filter;
    notifyListeners();
  }

  GameEntry? getEntryById(String id) {
    final gameId = int.tryParse(id);
    if (gameId == null) {
      return null;
    }

    for (final entry in _entries) {
      if (entry.game.id == gameId) {
        return entry;
      }
    }
    return null;
  }
}
