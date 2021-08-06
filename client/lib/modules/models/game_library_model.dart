import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:http/http.dart' as http;

class GameLibraryModel extends ChangeNotifier {
  // Library library = Library.create();
  List<LibraryEntry> entries = [];
  String _userId = '';

  void update(String userId) async {
    if (userId.isNotEmpty && userId != _userId) {
      _userId = userId;
      await fetch();
    }
  }

  Future<void> fetch() async {
    FirebaseFirestore.instance
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
        .snapshots()
        .listen((snapshot) {
      entries = snapshot.docs
          .map(
            (doc) => doc.data(),
          )
          .toList();
      notifyListeners();
    });
  }

  Future<List<LibraryEntry>> searchByTitle(String title) async {
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

    // TODO: Make this work again.
    // final entries = igdb.GameResult.fromBuffer(response.bodyBytes);
    // return entries.games;
    return [];
  }

  Future<bool> matchEntry(
      StoreEntry storeEntry, LibraryEntry libraryEntry) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/$_userId/match'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'encoded_store_entry': storeEntry.toJson(),
        'encoded_game': libraryEntry.toJson(),
      }),
    );

    if (response.statusCode != 200) {
      print('matchEntry (error): $response');
      return false;
    }

    fetch();
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

    fetch();
    return true;
  }
}
