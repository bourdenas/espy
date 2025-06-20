import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_view.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_index_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model that builds a view of the user's library.
class LibraryViewModel extends ChangeNotifier {
  AppConfigModel _appConfigModel = AppConfigModel();

  List<LibraryEntry> get library => getEntries(kLibrary);

  List<LibraryEntry> getEntries(String id) => LibraryView(_views[id] ?? [],
          ordering: _appConfigModel.libraryOrdering.value)
      .entries;

  void add(String id, List<GameDigest> games) {
    addEntries(id,
        games.map((digest) => LibraryEntry.fromGameDigest(digest)).toList());
  }

  void addEntries(String id, List<LibraryEntry> libraryEntries) {
    _views[id] = libraryEntries;
  }

  void update(
    AppConfigModel appConfigModel,
    LibraryIndexModel libraryIndexModel,
  ) {
    _appConfigModel = appConfigModel;
    _views[kLibrary] = libraryIndexModel.entries.toList();
    notifyListeners();
  }

  final Map<String, List<LibraryEntry>> _views = {};
}

const kLibrary = 'library';
