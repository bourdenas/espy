import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Model that handles interactions with remote library data store.
class GameLibraryModel extends ChangeNotifier {
  Library _library = Library();
  String userId = '';

  List<LibraryEntry> get entries => _library.entries;

  void update(UserData? userData) async {
    if (userData == null) {
      userId = '';
      _library = Library();
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
      _library =
          Library.fromJson(jsonDecode(encodedLibrary) as Map<String, dynamic>);
      notifyListeners();
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
      _library = snapshot.data() ?? Library();
      notifyListeners();
      _saveLocally();
    });
  }

  Future<List<GameEntry>> searchByTitle(
    String title, {
    baseGameOnly = false,
  }) async {
    if (title.isEmpty) return [];

    final response = await http.post(
      Uri.parse('${Urls.espyBackend}/search'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'title': title,
        'base_game_only': baseGameOnly,
      }),
    );

    if (response.statusCode != 200) {
      return [];
    }

    final jsonObj = jsonDecode(response.body) as List<dynamic>;
    return jsonObj.map((obj) => GameEntry.fromJson(obj)).toList();
  }

  Future<bool> retrieveGameEntry(int gameId) async {
    final response = await http.post(
      Uri.parse('${Urls.espyBackend}/resolve'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'game_id': gameId,
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }

  Future<bool> matchEntry(StoreEntry storeEntry, GameEntry gameEntry) async {
    final response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/$userId/match'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'store_entry': storeEntry.toJson(),
        'game_entry': gameEntry.toJson(),
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
      Uri.parse('${Urls.espyBackend}/library/$userId/match'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
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
    GameEntry gameEntry,
  ) async {
    final response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/$userId/rematch'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'store_entry': storeEntry.toJson(),
        'game_entry': gameEntry.toJson(),
        'unmatch_entry': libraryEntry.toJson(),
        'exact_match': true,
      }),
    );

    if (response.statusCode != 200) {
      return false;
    }

    return true;
  }
}
