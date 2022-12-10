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
  List<LibraryEntry> _entries = [];
  List<StoreEntry> _failedEntries = [];
  String userId = '';
  int _firebaseLibraryVersion = 0;

  List<LibraryEntry> get entries => _entries;
  List<StoreEntry> get failedEntries => _failedEntries;

  void update(UserData? userData) async {
    if (userData == null) {
      userId = '';
      _entries.clear();
      _failedEntries.clear();
      return;
    }

    if (userData.uid == userId && userData.version == _firebaseLibraryVersion) {
      return;
    }
    userId = userData.uid;
    _firebaseLibraryVersion = userData.version ?? 0;

    await _loadLibrary();
    notifyListeners();
  }

  Future<void> _loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();

    final localVersion = prefs.getInt('${userId}_version') ?? 0;
    final encodedLibrary = prefs.getString('${userId}_library');
    final encodedFailed = prefs.getString('${userId}_failed');

    if (_firebaseLibraryVersion == localVersion && encodedLibrary != null) {
      print('found local library for $userId @$localVersion');
      _entries =
          Library.fromJson(jsonDecode(encodedLibrary) as Map<String, dynamic>)
              .entries;
      _failedEntries = FailedEntries.fromJson(
              jsonDecode(encodedFailed ?? '') as Map<String, dynamic>)
          .entries;
    } else {
      print(
          'retrieving library for $userId last updated @$_firebaseLibraryVersion');
      await _fetchLibrary();
      await _saveLibraryLocally(_firebaseLibraryVersion);
    }
  }

  Future<void> _saveLibraryLocally(int version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${userId}_library', jsonEncode(Library(_entries)));
    await prefs.setString(
        '${userId}_failed', jsonEncode(FailedEntries(_failedEntries)));
    await prefs.setInt('${userId}_version', version);
  }

  Future<void> _fetchLibrary() async {
    final librarySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('library')
        .withConverter<LibraryEntry>(
          fromFirestore: (snapshot, _) =>
              LibraryEntry.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .orderBy('release_date', descending: true)
        .get();
    _entries = librarySnapshot.docs.map((doc) => doc.data()).toList();

    final failedSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('failed')
        .withConverter<StoreEntry>(
          fromFirestore: (snapshot, _) => StoreEntry.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .orderBy('title')
        .get();
    _failedEntries = failedSnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<GameEntry>> searchByTitle(
    String title, {
    baseGameOnly = false,
  }) async {
    if (title.isEmpty) return [];

    var response = await http.post(
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
      print(
          'matchEntry (error): ${response.statusCode} ${response.reasonPhrase}');
      return [];
    }

    final jsonObj = jsonDecode(response.body) as List<dynamic>;
    return jsonObj.map((obj) => GameEntry.fromJson(obj)).toList();
  }

  Future<bool> retrieveGameEntry(int gameId) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/retrieve'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'game_id': gameId,
      }),
    );

    if (response.statusCode != 200) {
      print(
          'retrieveGameEntry (error): ${response.statusCode} ${response.reasonPhrase}');
      return false;
    }

    return true;
  }

  Future<bool> matchEntry(StoreEntry storeEntry, GameEntry gameEntry) async {
    var response = await http.post(
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
      print(
          'matchEntry (error): ${response.statusCode} ${response.reasonPhrase}');
      return false;
    }

    return true;
  }

  Future<bool> unmatchEntry(
    StoreEntry storeEntry,
    LibraryEntry libraryEntry, {
    bool delete = false,
  }) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/$userId/unmatch'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'store_entry': storeEntry.toJson(),
        'library_entry': libraryEntry.toJson(),
        'delete': delete,
      }),
    );

    if (response.statusCode != 200) {
      print(
          'matchEntry (error): ${response.statusCode} ${response.reasonPhrase}');
      return false;
    }

    return true;
  }

  Future<bool> rematchEntry(
    StoreEntry storeEntry,
    LibraryEntry libraryEntry,
    GameEntry gameEntry,
  ) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/$userId/rematch'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'store_entry': storeEntry.toJson(),
        'library_entry': libraryEntry.toJson(),
        'game_entry': gameEntry.toJson(),
      }),
    );

    if (response.statusCode != 200) {
      print(
          'matchEntry (error): ${response.statusCode} ${response.reasonPhrase}');
      return false;
    }

    return true;
  }
}
