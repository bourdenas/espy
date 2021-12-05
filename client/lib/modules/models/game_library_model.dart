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

class GameLibraryModel extends ChangeNotifier {
  List<LibraryEntry> entries = [];
  String _userId = '';
  int _libraryVersion = 0;

  void update(UserData? userData) async {
    if (userData == null) {
      _userId = '';
      entries.clear();
      return;
    }

    if (userData.uid == _userId && userData.lastUpdate == _libraryVersion) {
      return;
    }
    _userId = userData.uid;
    _libraryVersion = userData.lastUpdate ?? 0;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final localVersion = prefs.getInt('${_userId}_version') ?? 0;
    final encodedLibrary = prefs.getString(_userId);
    if (_libraryVersion == localVersion && encodedLibrary != null) {
      print('found local library for $_userId from $localVersion');
      final jsonMap = jsonDecode(encodedLibrary) as Map<String, dynamic>;
      entries = Library.fromJson(jsonMap).entries;
    } else {
      print('retrieving library for $_userId last updated @$_libraryVersion');
      await fetchLibrary();
      await prefs.setString(_userId, jsonEncode(Library(entries)));
      await prefs.setInt('${_userId}_version', _libraryVersion);
    }

    notifyListeners();
  }

  Future<void> fetchLibrary() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('library')
        .withConverter<LibraryEntry>(
          fromFirestore: (snapshot, _) =>
              LibraryEntry.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .orderBy('release_date', descending: true)
        .get();

    entries.clear();
    entries.addAll(snapshot.docs.map((doc) => doc.data()));
  }

  void postDetails(LibraryEntry entry) async {
    entry.userData.tags.sort();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('library')
        .doc(entry.id.toString())
        .set(entry.toJson());
    notifyListeners();
  }

  Future<List<GameEntry>> searchByTitle(String title) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/search'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'title': title,
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

  Future<bool> matchEntry(StoreEntry storeEntry, GameEntry gameEntry) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/$_userId/recon'),
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

  Future<void> unmatchEntry(
      StoreEntry storeEntry, LibraryEntry libraryEntry) async {
    libraryEntry.storeEntries
        .removeWhere((entry) => entry.storefront == storeEntry.storefront);

    if (libraryEntry.storeEntries.isEmpty) {
      entries.removeWhere((entry) => entry.id == libraryEntry.id);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('library')
          .doc(libraryEntry.id.toString())
          .delete();
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('library')
          .doc(libraryEntry.id.toString())
          .set(libraryEntry.toJson());
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('unknown')
        .doc(storeEntry.id.toString())
        .set(storeEntry.toJson());

    notifyListeners();
  }
}
