import 'dart:convert';

import 'package:espy/constants/urls.dart';
import 'package:espy/proto/igdbapi.pb.dart' as igdb;
import 'package:espy/proto/library.pb.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:http/http.dart' as http;

class GameLibraryModel extends ChangeNotifier {
  Library library = Library.create();

  void fetch() async {
    final response =
        await http.get(Uri.parse('${Urls.espyBackend}/library/testing'));

    if (response.statusCode == 200) {
      final lib = Library.fromBuffer(response.bodyBytes);
      _update(lib);
    } else {
      throw Exception('Failed to load game library');
    }
  }

  /// Updates the model with new entries from input [Library].
  void _update(Library lib) {
    library = lib;
    library.entry.sort((a, b) => -a.game.firstReleaseDate.seconds
        .compareTo(b.game.firstReleaseDate.seconds));

    notifyListeners();
  }

  /// Removes all games from the model.
  void clear() {
    library.clear();
    notifyListeners();
  }

  Future<List<igdb.Game>> searchByTitle(String title) async {
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

    final entries = igdb.GameResult.fromBuffer(response.bodyBytes);
    return entries.games;
  }

  Future<bool> matchEntry(StoreEntry storeEntry, igdb.Game game) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/testing/match'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'encoded_store_entry': storeEntry.writeToBuffer(),
        'encoded_game': game.writeToBuffer(),
      }),
    );

    if (response.statusCode != 200) {
      print('matchEntry (error): $response');
      return false;
    }

    fetch();
    return true;
  }

  Future<bool> unmatchEntry(StoreEntry storeEntry, igdb.Game game) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/testing/unmatch'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'encoded_store_entry': storeEntry.writeToBuffer(),
        'encoded_game': game.writeToBuffer(),
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
