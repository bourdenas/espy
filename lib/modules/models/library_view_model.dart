import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/remote_library_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model that handles LibraryEntries that are currently in view.
class LibraryViewModel extends ChangeNotifier {
  List<LibraryEntry> _libraryEntries = const [];

  Iterable<LibraryEntry> get entries => _libraryEntries;

  void update(
    LibraryEntriesModel libraryModel,
    LibraryFilterModel filterModel,
    RemoteLibraryModel remoteModel,
  ) async {
    _libraryEntries = libraryModel.filter(filterModel.filter).toList();
    _libraryEntries.addAll(remoteModel.entries);

    notifyListeners();
  }
}
