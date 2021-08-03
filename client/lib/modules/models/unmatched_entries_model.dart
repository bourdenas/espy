import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/proto/library.pb.dart' show StoreEntry;
import 'package:flutter/foundation.dart' show ChangeNotifier;

class UnknownEntriesModel extends ChangeNotifier {
  List<StoreEntry> _entries = [];

  UnmodifiableListView<StoreEntry> get entries =>
      UnmodifiableListView(_entries);

  void update(String userId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('unknown')
        .limit(5)
        .snapshots()
        .listen((snapshot) {
      _entries = snapshot.docs
          .map(
            (doc) => StoreEntry(
              title: doc.data()['title'],
            ),
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
  UnknownEntriesModel? _unknownModel;
  String _searchPhrase = '';

  UnmodifiableListView<StoreEntry> get entries => _unknownModel != null
      ? UnmodifiableListView(_unknownModel!.entries
          .where((e) => e.title.toLowerCase().contains(_searchPhrase)))
      : UnmodifiableListView([]);

  void update(UnknownEntriesModel unknownModel, String searchPhrase) {
    _unknownModel = unknownModel;
    _searchPhrase = searchPhrase;

    notifyListeners();
  }
}
