import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model of all unreconciled entries in user's library.
class UnmatchedLibraryModel extends ChangeNotifier {
  String _userId = '';
  List<StoreEntry> _entries = [];

  UnmodifiableListView<StoreEntry> get entries =>
      UnmodifiableListView(_entries);

  void update(UserData? userData) async {
    if (userData == null) {
      _userId = '';
      _entries.clear();
      return;
    }

    if (userData.uid == _userId) {
      return;
    }
    _userId = userData.uid;

    await _loadUnknownEntries();
  }

  Future<void> _loadUnknownEntries() async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('unknown')
        .withConverter<StoreEntry>(
          fromFirestore: (snapshot, _) => StoreEntry.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .snapshots()
        .listen((snapshot) {
      _entries = snapshot.docs
          .map(
            (doc) => doc.data(),
          )
          .toList()
        ..sort((l, r) {
          return l.title.compareTo(r.title);
        });
      notifyListeners();
    });
  }
}

class UnmatchedEntriesModel extends ChangeNotifier {
  UnmatchedLibraryModel? _unknownModel;
  String _searchPhrase = '';

  UnmodifiableListView<StoreEntry> get entries => _unknownModel != null
      ? UnmodifiableListView(_unknownModel!.entries
          .where((e) => e.title.toLowerCase().contains(_searchPhrase)))
      : UnmodifiableListView([]);

  void update(UnmatchedLibraryModel unknownModel, String searchPhrase) {
    _unknownModel = unknownModel;
    _searchPhrase = searchPhrase;

    notifyListeners();
  }
}
