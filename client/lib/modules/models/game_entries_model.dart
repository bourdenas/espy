import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class GameEntriesModel extends ChangeNotifier {
  Map<int, LibraryEntry> _entries = {};
  GameTagsModel _gameTags = GameTagsModel();

  void update(
    List<LibraryEntry> library,
    List<LibraryEntry> wishlist,
    GameTagsModel gameTags,
  ) {
    _entries = Map.fromEntries(library.map((e) => MapEntry(e.id, e)));
    _entries.addAll(Map.fromEntries(wishlist.map((e) => MapEntry(e.id, e))));
    _gameTags = gameTags;
    notifyListeners();
  }

  bool get isNotEmpty => _entries.isNotEmpty;

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

  Iterable<LibraryEntry> getRecentEntries() {
    return _entries.values.toList()
      ..sort((a, b) => -a.addedDate.compareTo(b.addedDate));
  }

  LibraryEntry? getEntryByStringId(String id) {
    final gameId = int.tryParse(id);
    if (gameId == null) {
      return null;
    }

    return _entries[gameId];
  }

  LibraryEntry? getEntryById(int id) {
    return _entries[id];
  }
}
