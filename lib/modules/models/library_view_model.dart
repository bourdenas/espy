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
  UserLibraryModel _libraryModel = UserLibraryModel();
  WishlistModel _wishlistModel = WishlistModel();
  GameTagsModel _gameTagsModel = GameTagsModel();

  LibraryView _view = LibraryView([]);

  int get length => _view.length;
  Iterable<LibraryEntry> get entries => _view.entries;
  List<(String, List<LibraryEntry>)> get groups => _view.group(
        _appConfigModel.libraryGrouping.value,
        _gameTagsModel.genreTags.byGameId,
      );

  void update(
    AppConfigModel appConfigModel,
    GameTagsModel gameTags,
    UserLibraryModel userLibraryModel,
    WishlistModel wishlistModel,
    RemoteLibraryModel remoteLibraryModel,
    LibraryFilterModel filterModel,
  ) {
    _appConfigModel = appConfigModel;
    _libraryModel = userLibraryModel;
    _wishlistModel = wishlistModel;
    _gameTagsModel = gameTags;

    _view = filterModel.filter.isNotEmpty
        ? filterModel.filter.apply(_gameTagsModel, _getEntryById)
        : LibraryView(_libraryModel.entries.toList());
    if (!_appConfigModel.showExpansions.value) {
      _view.removeExpansions();
    }
    _view.addEntries(_appConfigModel.showExpansions.value
        ? remoteLibraryModel.entriesWithExpansions
        : remoteLibraryModel.entries);
    _view.sort(appConfigModel.libraryOrdering.value);

    notifyListeners();
  }

  LibraryEntry? _getEntryById(int id) =>
      _libraryModel.getEntryById(id) ?? _wishlistModel.getEntryById(id);
}
