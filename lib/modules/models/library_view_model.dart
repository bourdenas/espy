import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_view.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_index_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model that builds a view of the user's library.
class LibraryViewModel extends ChangeNotifier {
  LibraryView _view = LibraryView([]);

  Iterable<LibraryEntry> get entries => _view.entries;
  int get length => _view.length;

  void update(
    AppConfigModel appConfigModel,
    LibraryIndexModel libraryIndexModel,
  ) {
    _view = LibraryView(
      libraryIndexModel.entries.toList(),
      ordering: appConfigModel.libraryOrdering.value,
    );
    notifyListeners();
  }
}
