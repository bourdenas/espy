import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class WishlistModel extends ChangeNotifier {
  String _userId = '';
  Library _wishlist = Library();

  UnmodifiableListView<LibraryEntry> get wishlist =>
      UnmodifiableListView(_wishlist.entries.reversed);

  void update(UserData? userData) async {
    if (userData == null) {
      _userId = '';
      _wishlist = Library();
      return;
    }

    if (userData.uid.isEmpty || userData.uid == _userId) {
      return;
    }

    _userId = userData.uid;
    _loadRecent(_userId);
  }

  Future<void> _loadRecent(String userId) async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('games')
        .doc('wishlist')
        .withConverter<Library>(
          fromFirestore: (snapshot, _) => Library.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => {},
        )
        .snapshots()
        .listen((DocumentSnapshot<Library> snapshot) {
      _wishlist = snapshot.data() ?? Library();

      notifyListeners();
    });
  }
}
