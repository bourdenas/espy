import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class GameEntriesModel extends ChangeNotifier {
  List<LibraryEntry> _entries = [];
  GameTagsModel _gameTags = GameTagsModel();

  void update(List<LibraryEntry> entries, GameTagsModel gameTags) {
    _entries = entries;
    _gameTags = gameTags;
    notifyListeners();
  }

  Iterable<LibraryEntry> getEntries({LibraryFilter? filter}) {
    if (filter == null) {
      return _entries;
    }

    final taggedEntries = filter.tags.isNotEmpty
        ? Set<int>.from(_gameTags.entriesByTag(filter.tags.first))
        : null;

    final entries = taggedEntries != null
        ? _entries.where((e) => taggedEntries.contains(e.id))
        : _entries;

    return entries.where((e) => filter.apply(e));
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
