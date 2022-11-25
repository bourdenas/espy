import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class GameEntriesModel extends ChangeNotifier {
  Map<int, LibraryEntry> _entries = {};
  GameTagsModel _gameTags = GameTagsModel();

  void update(List<LibraryEntry> entries, GameTagsModel gameTags) {
    _entries = Map.fromEntries(entries.map((e) => MapEntry(e.id, e)));
    _gameTags = gameTags;
    notifyListeners();
  }

  Iterable<LibraryEntry> getEntries({LibraryFilter? filter}) {
    if (filter == null) {
      return _entries.values;
    }

    final taggedEntries = filter.tags.isNotEmpty
        ? _gameTags.entriesByTag(filter.tags.first)
        : null;

    final entries = taggedEntries != null
        ? taggedEntries
            .map((id) => _entries[id])
            .whereType<LibraryEntry>()
            .toList()
        : _entries.values;

    final sortedEntries = entries.toList()
      ..sort((a, b) => -a.releaseDate.compareTo(b.releaseDate));

    return sortedEntries.where((e) => filter.apply(e));
  }

  LibraryEntry? getEntryById(String id) {
    final gameId = int.tryParse(id);
    if (gameId == null) {
      return null;
    }

    return _entries[gameId];
  }
}
