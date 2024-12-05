import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/library.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:http/http.dart' as http;

class WishlistModel extends ChangeNotifier {
  String _userId = '';

  // The user wishlist.
  Library _wishlist = const Library();

  Iterable<LibraryEntry> get entries => _wishlist.entries;

  bool contains(int id) => entries.any((e) => e.id == id);

  void update(UserData? userData) async {
    if (userData == null) {
      _userId = '';
      _wishlist = const Library();
      return;
    }

    if (userData.uid.isEmpty || userData.uid == _userId) {
      return;
    }

    _userId = userData.uid;
    _loadWishlist(_userId);
  }

  Future<void> _loadWishlist(String userId) async {
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
      _wishlist = snapshot.data() ?? const Library();

      notifyListeners();
    });
  }

  Future<void> addToWishlist(LibraryEntry libraryEntry) async {
    await http.post(
      Uri.parse('${Urls.espyBackend}/library/wishlist'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'user_id': _userId,
        'add_game': libraryEntry.toJson(),
      }),
    );
  }

  Future<void> removeFromWishlist(int gameId) async {
    await http.post(
      Uri.parse('${Urls.espyBackend}/library/wishlist'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'user_id': _userId,
        'remove_game': gameId,
      }),
    );
  }
}
