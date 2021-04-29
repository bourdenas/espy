import 'dart:collection';

import 'package:espy/proto/library.pb.dart' show Library, StoreEntry;
import 'package:flutter/foundation.dart' show ChangeNotifier;

class UnmatchedEntriesModel extends ChangeNotifier {
  List<StoreEntry> _entries = [];
  String _titleSearchPhrase = '';

  UnmodifiableListView<StoreEntry> get entries => UnmodifiableListView(_entries
      .where((e) => e.title.toLowerCase().contains(_titleSearchPhrase)));

  void update(Library library, String titleSearchPhrase) {
    _entries = library.unreconciledStoreEntry
      ..sort((l, r) {
        return l.title.compareTo(r.title);
      });
    _titleSearchPhrase = titleSearchPhrase;

    notifyListeners();
  }
}
