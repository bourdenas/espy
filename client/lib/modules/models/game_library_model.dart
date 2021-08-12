import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:http/http.dart' as http;

class GameLibraryModel extends ChangeNotifier {
  List<LibraryEntry> entries = [];
  String _userId = '';

  void update(String userId) async {
    if (userId.isNotEmpty && userId != _userId) {
      _userId = userId;
      await _fetch();
    }
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

  Future<void> _fetch() async {
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
        .limit(20)
        .get();

    entries = snapshot.docs.map((doc) => doc.data()).toList();
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
      print('searchByTitle (error): $response');
      return [];
    }

    final jsonObj = jsonDecode(response.body) as List<dynamic>;
    return jsonObj.map((obj) => GameEntry.fromJson(obj)).toList();
  }

  Future<bool> matchEntry(StoreEntry storeEntry, GameEntry gameEntry) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/$_userId/match'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'encoded_store_entry': storeEntry.toJson(),
        'encoded_game': gameEntry.toJson(),
      }),
    );

    if (response.statusCode != 200) {
      print('matchEntry (error): $response');
      return false;
    }

    _fetch();
    return true;
  }

  Future<bool> unmatchEntry(
      StoreEntry storeEntry, LibraryEntry libraryEntry) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/$_userId/unmatch'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'encoded_store_entry': storeEntry.toJson(),
        'encoded_game': libraryEntry.toJson(),
      }),
    );

    if (response.statusCode != 200) {
      print('unmatchEntry (error): $response');
      return false;
    }

    _fetch();
    return true;
  }
}
