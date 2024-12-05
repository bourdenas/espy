import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/library.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Model that handles interactions with remote library data store.
class UserLibraryModel extends ChangeNotifier {
  String userId = '';

  // The user library.
  Library _library = const Library();

  bool get isNotEmpty => _library.entries.isNotEmpty;
  Iterable<LibraryEntry> get all => _library.entries;
  Iterable<LibraryEntry> get entries =>
      _library.entries.where((e) => e.isStandaloneGame || e.isExpansion);

  void update(UserData? userData) async {
    if (userData == null) {
      userId = '';
      _library = const Library();
      notifyListeners();
      return;
    }

    if (userData.uid == userId) {
      return;
    }
    userId = userData.uid;

    await _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedLibrary = prefs.getString('${userId}_library');
    if (encodedLibrary != null) {
      try {
        _library = Library.fromJson(
            jsonDecode(encodedLibrary) as Map<String, dynamic>);
        notifyListeners();
      } catch (_) {}
    }

    _fetch();
  }

  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${userId}_library', jsonEncode(_library));
  }

  Future<void> _fetch() async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('games')
        .doc('library')
        .withConverter<Library>(
          fromFirestore: (snapshot, _) => Library.fromJson(snapshot.data()!),
          toFirestore: (library, _) => library.toJson(),
        )
        .snapshots()
        .listen((DocumentSnapshot<Library> snapshot) {
      _library = snapshot.data() ?? const Library();
      notifyListeners();
      _saveLocally();
    });
  }

  Future<bool> matchEntry(StoreEntry storeEntry, int gameId) async {
    final response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/match'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'user_id': userId,
        'store_entry': storeEntry.toJson(),
        'game_id': gameId,
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }

  Future<bool> unmatchEntry(
    StoreEntry storeEntry,
    LibraryEntry libraryEntry, {
    bool delete = false,
  }) async {
    final response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/match'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'user_id': userId,
        'store_entry': storeEntry.toJson(),
        'unmatch_entry': libraryEntry.toJson(),
        'delete_unmatched': delete,
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }

  Future<bool> rematchEntry(
    StoreEntry storeEntry,
    LibraryEntry libraryEntry,
    int gameId,
  ) async {
    final response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/match'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'user_id': userId,
        'store_entry': storeEntry.toJson(),
        'game_id': gameId,
        'unmatch_entry': libraryEntry.toJson(),
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }

  Future<bool> updateEntry(LibraryEntry libraryEntry) async {
    final response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/update'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'user_id': userId,
        'game_id': libraryEntry.id,
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }
}
