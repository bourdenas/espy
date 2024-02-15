import 'dart:collection';
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

  // User library indexed by game id.
  HashMap<int, LibraryEntry> _gamesById = HashMap();

  Iterable<LibraryEntry> get entries => _wishlist.entries.reversed;
  HashMap<int, LibraryEntry> get gamesById => _gamesById;

  void _setWishlist(Library wishlist) {
    _wishlist = wishlist;
    _gamesById =
        HashMap.fromEntries(_wishlist.entries.map((e) => MapEntry(e.id, e)));
  }

  void update(UserData? userData) async {
    if (userData == null) {
      _userId = '';
      _setWishlist(const Library());
      return;
    }

    if (userData.uid.isEmpty || userData.uid == _userId) {
      return;
    }

    _userId = userData.uid;
    _loadWishlist(_userId);
  }

  bool contains(int id) => _gamesById[id] != null;

  LibraryEntry? getEntryById(int id) => _gamesById[id];

  LibraryEntry? getEntryByStringId(String id) {
    final gameId = int.tryParse(id);
    if (gameId == null) {
      return null;
    }

    return getEntryById(gameId);
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
      _setWishlist(snapshot.data() ?? const Library());

      notifyListeners();
    });
  }

  Future<void> addToWishlist(LibraryEntry libraryEntry) async {
    await http.post(
      Uri.parse('${Urls.espyBackend}/library/$_userId/wishlist'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'add_game': libraryEntry.toJson(),
      }),
    );
  }

  Future<void> removeFromWishlist(int gameId) async {
    await http.post(
      Uri.parse('${Urls.espyBackend}/library/$_userId/wishlist'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'remove_game': gameId,
      }),
    );
  }
}
