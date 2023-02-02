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

  bool contains(int game_id) {
    for (final entry in _wishlist.entries) {
      if (entry.id == game_id) return true;
    }
    return false;
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

  Future<void> add_to_wishlist(LibraryEntry libraryEntry) async {
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

  Future<void> remove_from_wishlist(int game_id) async {
    await http.post(
      Uri.parse('${Urls.espyBackend}/library/$_userId/wishlist'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'remove_game': game_id,
      }),
    );
  }
}