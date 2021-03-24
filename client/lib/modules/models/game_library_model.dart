import 'dart:collection';
import 'dart:convert';

import 'package:espy/proto/library.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String BACKEND_HOST = 'localhost:3030';
// const String BACKEND_HOST = '10.0.2.2:3030';

class GameLibraryModel extends ChangeNotifier {
  Library _library = Library.create();
  String _searchFilter = '';

  UnmodifiableListView<GameEntry> get games =>
      UnmodifiableListView(_library.entry
          .where((e) => e.game.name.toLowerCase().contains(_searchFilter)));

  void fetch() async {
    final response = await http.get(Uri.http(BACKEND_HOST, 'library/testing'));

    if (response.statusCode == 200) {
      final lib = Library.fromBuffer(response.bodyBytes);
      _update(lib);
    } else {
      throw Exception('Failed to load game library');
    }
  }

  void postDetails(GameEntry entry) async {
    var response = await http.post(
      Uri.http(BACKEND_HOST, '/library/testing/details/${entry.game.id}'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'tags': entry.details.tag,
      }),
    );
    if (response.statusCode != 200) {
      print('postDetails (error): $response');
    }
  }

  set titleFilter(String phrase) {
    if (phrase == _searchFilter) {
      return;
    }
    _searchFilter = phrase;
    notifyListeners();
  }

  GameEntry? getEntryById(String id) {
    final gameId = int.tryParse(id);
    if (gameId == null) {
      return null;
    }

    for (final entry in _library.entry) {
      if (entry.game.id == gameId) {
        return entry;
      }
    }
    return null;
  }

  /// Updates the model with new entries from input [Library].
  void _update(Library lib) {
    _library = lib;
    _library.entry.sort((a, b) => -a.game.firstReleaseDate.seconds
        .compareTo(b.game.firstReleaseDate.seconds));
    notifyListeners();
  }

  /// Removes all games from the model.
  void clear() {
    _library.clear();
    notifyListeners();
  }
}
