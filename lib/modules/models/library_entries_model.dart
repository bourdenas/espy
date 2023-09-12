import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/remote_library_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class LibraryEntriesModel extends ChangeNotifier {
  Map<int, LibraryEntry> _entries = {};
  AppConfigModel _appConfigModel = AppConfigModel();
  GameTagsModel _gameTagsModel = GameTagsModel();
  RemoteLibraryModel _remoteLibraryModel = RemoteLibraryModel();

  void update(
    AppConfigModel appConfigModel,
    UserLibraryModel userLibraryModel,
    WishlistModel wishlistModel,
    GameTagsModel gameTags,
    RemoteLibraryModel remoteLibraryModel,
  ) {
    _entries =
        Map.fromEntries(userLibraryModel.entries.map((e) => MapEntry(e.id, e)));
    _entries.addAll(
        Map.fromEntries(wishlistModel.wishlist.map((e) => MapEntry(e.id, e))));
    _appConfigModel = appConfigModel;
    _gameTagsModel = gameTags;
    _remoteLibraryModel = remoteLibraryModel;
    notifyListeners();
  }

  bool get isNotEmpty => _entries.isNotEmpty;

  Iterable<int> get all => _entries.keys;

  LibraryView filter(LibraryFilter filter, {bool showOutOfLib = false}) {
    return filter.filter(
      this,
      _remoteLibraryModel,
      _gameTagsModel,
      showExpansions: _appConfigModel.showExpansions.value,
      showOutOfLib: showOutOfLib,
    );
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

  bool inLibrary(int id) {
    return _entries[id]?.storeEntries.isNotEmpty ?? false;
  }
}
