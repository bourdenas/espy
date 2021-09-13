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

  Future<void> fetchAll() async {
    if (_isFinished) {
      return;
    }

    _isFetching = true;

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
        .startAfterDocument(_lastDocument!)
        .get();

    _isFinished = true;

    entries.addAll(snapshot.docs.map((doc) => doc.data()));
    _lastDocument = snapshot.docs[snapshot.docs.length - 1];

    notifyListeners();
    _isFetching = false;
  }

  Future<void> fetch({int limit = 10}) async {
    if (_isFetching || _isFinished) {
      return;
    }

    _isFetching = true;
    final snapshot = _lastDocument == null
        ? await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('library')
            .withConverter<LibraryEntry>(
              fromFirestore: (snapshot, _) =>
                  LibraryEntry.fromJson(snapshot.data()!),
              toFirestore: (entry, _) => entry.toJson(),
            )
            .orderBy('release_date', descending: true)
            .limit(limit)
            .get()
        : await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('library')
            .withConverter<LibraryEntry>(
              fromFirestore: (snapshot, _) =>
                  LibraryEntry.fromJson(snapshot.data()!),
              toFirestore: (entry, _) => entry.toJson(),
            )
            .orderBy('release_date', descending: true)
            .startAfterDocument(_lastDocument!)
            .limit(limit)
            .get();

    _isFinished = snapshot.docs.isEmpty;

    entries.addAll(snapshot.docs.map((doc) => doc.data()));
    _lastDocument = snapshot.docs[snapshot.docs.length - 1];

    notifyListeners();
    _isFetching = false;
  }

  bool _isFetching = false;
  bool _isFinished = false;
  QueryDocumentSnapshot? _lastDocument;

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
