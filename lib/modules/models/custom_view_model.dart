import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_view.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model that builds a LibraryView.
class CustomViewModel extends ChangeNotifier {
  AppConfigModel _appConfigModel = AppConfigModel();
  LibraryView _view = LibraryView([]);
  List<LibraryEntry> _libraryEntries = [];

  Iterable<LibraryEntry> get entries => _view.entries;
  int get length => _libraryEntries.length;

  void update(AppConfigModel appConfigModel) {
    _appConfigModel = appConfigModel;

    _view = LibraryView(
      _libraryEntries,
      ordering: _appConfigModel.libraryOrdering.value,
    );

    notifyListeners();
  }

  set games(List<LibraryEntry> libraryEntries) {
    _libraryEntries = libraryEntries;
    _view = LibraryView(
      _libraryEntries,
      ordering: _appConfigModel.libraryOrdering.value,
    );

    notifyListeners();
  }

  set digests(Iterable<GameDigest> digests) {
    games =
        digests.map((digest) => LibraryEntry.fromGameDigest(digest)).toList();
  }

  void clear() => games = [];
}
