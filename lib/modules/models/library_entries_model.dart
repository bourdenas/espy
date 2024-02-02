import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/remote_library_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class LibraryEntriesModel extends ChangeNotifier {
  Map<int, LibraryEntry> _library = {};
  Map<int, LibraryEntry> _wishlist = {};
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
    _library =
        Map.fromEntries(userLibraryModel.entries.map((e) => MapEntry(e.id, e)));
    _wishlist =
        Map.fromEntries(wishlistModel.wishlist.map((e) => MapEntry(e.id, e)));
    _appConfigModel = appConfigModel;
    _gameTagsModel = gameTags;
    _remoteLibraryModel = remoteLibraryModel;
    notifyListeners();
  }

  bool get isNotEmpty => _library.isNotEmpty;

  Iterable<LibraryEntry> get library => _library.values;
  Iterable<LibraryEntry> get wishlist => _wishlist.values;
  Iterable<LibraryEntry> get all =>
      [_library.values, _wishlist.values].expand((e) => e);

  Iterable<int> get libraryIds => _library.keys;
  Iterable<int> get wishlistIds => _wishlist.keys;
  Iterable<int> get allIds => [_library.keys, _wishlist.keys].expand((e) => e);

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
    return _library.values.toList()
      ..sort((a, b) => -a.addedDate.compareTo(b.addedDate));
  }

  LibraryEntry? getEntryByStringId(String id) {
    final gameId = int.tryParse(id);
    if (gameId == null) {
      return null;
    }

    return _library[gameId];
  }

  LibraryEntry? getEntryById(int id) {
    return _library[id] ?? _wishlist[id];
  }

  bool inLibrary(int id) {
    return _library[id] != null;
  }
}
