import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class LibraryEntriesModel extends ChangeNotifier {
  Map<int, LibraryEntry> _entries = {};
  GameTagsModel _gameTagsModel = GameTagsModel();

  void update(
    List<LibraryEntry> library,
    List<LibraryEntry> wishlist,
    GameTagsModel gameTags,
  ) {
    _entries = Map.fromEntries(library.map((e) => MapEntry(e.id, e)));
    _entries.addAll(Map.fromEntries(wishlist.map((e) => MapEntry(e.id, e))));
    _gameTagsModel = gameTags;
    notifyListeners();
  }

  bool get isNotEmpty => _entries.isNotEmpty;

  Iterable<int> get all => _entries.keys;

  Iterable<LibraryEntry> filter(LibraryFilter filter) {
    return filter.filter(this, _gameTagsModel).toList()
      ..sort((a, b) => -a.releaseDate.compareTo(b.releaseDate));
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
