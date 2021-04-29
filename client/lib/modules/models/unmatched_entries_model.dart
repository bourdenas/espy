import 'dart:collection';

import 'package:espy/proto/library.pb.dart' show Library, StoreEntry;
import 'package:flutter/foundation.dart' show ChangeNotifier;

class UnmatchedEntriesModel extends ChangeNotifier {
  List<StoreEntry> _entries = [];
  String _searchPhrase = '';

  UnmodifiableListView<StoreEntry> get entries => UnmodifiableListView(
      _entries.where((e) => e.title.toLowerCase().contains(_searchPhrase)));

  void update(Library library, String searchPhrase) {
    if (_searchPhrase == searchPhrase) {
      // Poor man's approach to avoid costly reindexing. I'd rather have updates
      // per dependency.
      _entries = library.unreconciledStoreEntry
        ..sort((l, r) {
          return l.title.compareTo(r.title);
        });
    }

    _searchPhrase = searchPhrase;

    notifyListeners();
  }
}
