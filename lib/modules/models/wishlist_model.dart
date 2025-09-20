import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/library.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class WishlistModel extends ChangeNotifier {
  String _userId = '';
  StreamSubscription? _subscription;

  // The user wishlist.
  Library _wishlist = const Library();

  List<LibraryEntry> get entries => _wishlist.entries;

  bool contains(int id) => entries.any((e) => e.id == id);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void update(UserData? userData) async {
    if (userData == null) {
      _userId = '';
      _wishlist = const Library();
      _subscription = null;
      notifyListeners();
      return;
    }

    if (userData.uid.isEmpty || userData.uid == _userId) {
      return;
    }

    _userId = userData.uid;
    await _subscription?.cancel();
    _loadWishlist(_userId);
  }

  Future<void> _loadWishlist(String userId) async {
    _subscription = FirebaseFirestore.instance
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
      _wishlist = snapshot.data() ?? const Library();

      notifyListeners();
    });
  }
}
