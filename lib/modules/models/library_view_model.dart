import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_view.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/modules/models/library_index_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model that represents what is visible in a library screen.
class LibraryViewModel extends ChangeNotifier {
  AppConfigModel _appConfigModel = AppConfigModel();
  LibraryView _view = LibraryView([], AppConfigModel());

  Iterable<LibraryEntry> get entries => _view.entries;

  List<(String, List<LibraryEntry>)> get groups =>
      _view.group(_appConfigModel.libraryGrouping.value);

  int get length => _view.length;

  LibraryViewModel();
  LibraryViewModel.custom(Iterable<LibraryEntry> entries) {
    _view = LibraryView(entries, _appConfigModel);
  }

  void update(
    AppConfigModel appConfigModel,
    LibraryIndexModel libraryIndexModel,
    CustomViewModel customViewModel,
  ) {
    _appConfigModel = appConfigModel;

    _view = LibraryView(
        customViewModel.games.isEmpty
            ? libraryIndexModel.entries
            : customViewModel.games,
        _appConfigModel);
    notifyListeners();
  }
}
