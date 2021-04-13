import 'dart:collection';

import 'package:espy/proto/library.pb.dart' show Library, StoreEntry;
import 'package:flutter/foundation.dart' show ChangeNotifier;

class UnmatchedEntriesModel extends ChangeNotifier {
  List<StoreEntry> _entries = [];

  UnmodifiableListView<StoreEntry> get entries =>
      UnmodifiableListView(_entries);

  void update(Library library) {
    _entries = library.unreconciledStoreEntry;
    notifyListeners();
  }
}
