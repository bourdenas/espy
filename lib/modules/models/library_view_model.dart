import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/filtering/library_view.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/library_index_model.dart';
import 'package:espy/modules/models/remote_library_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model that represents what is visible at the /games screen.
class LibraryViewModel extends ChangeNotifier {
  AppConfigModel _appConfigModel = AppConfigModel();
  LibraryIndexModel _libraryIndexModel = LibraryIndexModel();
  GameTagsModel _gameTagsModel = GameTagsModel();

  LibraryView _view = LibraryView([]);

  int get length => _view.length;
  Iterable<LibraryEntry> get entries => _view.entries;
  List<(String, List<LibraryEntry>)> get groups => _view.group(
        _appConfigModel.libraryGrouping.value,
        _gameTagsModel.genreTags.byGameId,
      );

  LibraryViewModel();

  LibraryViewModel.custom(
    AppConfigModel appConfigModel,
    Iterable<LibraryEntry> entries,
    LibraryFilter filter,
  ) {
    _appConfigModel = appConfigModel;
    _libraryIndexModel = LibraryIndexModel()..update(entries);
    _gameTagsModel = GameTagsModel()..update('', _libraryIndexModel);

    _view = filter.isNotEmpty
        ? filter.apply(_gameTagsModel, _getEntryById)
        : LibraryView(entries.toList());
    if (!_appConfigModel.showExpansions.value) {
      _view.removeExpansions();
    }
  }

  void update(
    AppConfigModel appConfigModel,
    GameTagsModel gameTags,
    LibraryIndexModel libraryIndexModel,
    RemoteLibraryModel remoteLibraryModel,
    LibraryFilterModel filterModel,
  ) {
    _appConfigModel = appConfigModel;
    _libraryIndexModel = libraryIndexModel;
    _gameTagsModel = gameTags;

    _view = filterModel.filter.isNotEmpty
        ? filterModel.filter.apply(_gameTagsModel, _getEntryById)
        : LibraryView(_libraryIndexModel.entries.toList());
    if (!_appConfigModel.showExpansions.value) {
      _view.removeExpansions();
    }
    _view.addEntries(_appConfigModel.showExpansions.value
        ? remoteLibraryModel.entriesWithExpansions
        : remoteLibraryModel.entries);
    _view.sort(appConfigModel.libraryOrdering.value);

    notifyListeners();
  }

  LibraryEntry? _getEntryById(int id) => _libraryIndexModel.getEntryById(id);
}
