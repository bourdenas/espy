import 'dart:collection';

import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_view.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/remote_library_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/wishlist_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model that represents what is visible at the /games screen.
class LibraryViewModel extends ChangeNotifier {
  AppConfigModel _appConfigModel = AppConfigModel();
  UserLibraryModel _userLibraryModel = UserLibraryModel();
  GameTagsModel _gameTagsModel = GameTagsModel();

  HashMap<int, LibraryEntry> _wishlist = HashMap();
  LibraryView _view = LibraryView([]);

  int get length => _view.length;
  Iterable<LibraryEntry> get entries => _view.all;
  List<(String, List<LibraryEntry>)> get groups =>
      _view.group(_appConfigModel.libraryGrouping.value);

  void update(
    AppConfigModel appConfigModel,
    GameTagsModel gameTags,
    UserLibraryModel userLibraryModel,
    WishlistModel wishlistModel,
    RemoteLibraryModel remoteLibraryModel,
    LibraryFilterModel filterModel,
  ) {
    _appConfigModel = appConfigModel;
    _userLibraryModel = userLibraryModel;
    _gameTagsModel = gameTags;

    _wishlist = HashMap.fromEntries(
        wishlistModel.entries.map((e) => MapEntry(e.id, e)));

    _view = filterModel.filter.isNotEmpty
        ? filterModel.filter.apply(_userLibraryModel.gamesById, _gameTagsModel)
        : LibraryView(_userLibraryModel.entries.toList());
    _view.addEntries(remoteLibraryModel.entries);
    _view.sort(appConfigModel.libraryOrdering.value);

    notifyListeners();
  }
}
