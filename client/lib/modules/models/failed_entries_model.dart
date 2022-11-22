import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model of all unreconciled entries in user's library.
class FailedEntriesModel extends ChangeNotifier {
  String _uid = '';
  List<StoreEntry> _entries = [];

  UnmodifiableListView<StoreEntry> get entries =>
      UnmodifiableListView(_entries);

  void update(String uid) async {
    if (uid == _uid) {
      return;
    }
    _uid = uid;

    await _loadUnmatchedEntries();
  }

  Future<void> _loadUnmatchedEntries() async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('failed')
        .withConverter<StoreEntry>(
          fromFirestore: (snapshot, _) => StoreEntry.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .snapshots()
        .listen(
      (QuerySnapshot<StoreEntry> snapshot) {
        _entries = snapshot.docs
            .map(
              (doc) => doc.data(),
            )
            .toList()
          ..sort((l, r) {
            return l.title.compareTo(r.title);
          });
        notifyListeners();
      },
    );
  }
}

class UnmatchedEntriesModel extends ChangeNotifier {
  FailedEntriesModel? _unknownModel;
  String _searchPhrase = '';

  UnmodifiableListView<StoreEntry> get entries => _unknownModel != null
      ? UnmodifiableListView(_unknownModel!.entries
          .where((e) => e.title.toLowerCase().contains(_searchPhrase)))
      : UnmodifiableListView([]);

  void update(FailedEntriesModel unknownModel, String searchPhrase) {
    _unknownModel = unknownModel;
    _searchPhrase = searchPhrase;

    notifyListeners();
  }
}
