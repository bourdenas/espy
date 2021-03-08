import 'dart:collection';

import 'package:espy/proto/library.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GameLibraryModel extends ChangeNotifier {
  final List<GameEntry> _entries = [];

  UnmodifiableListView<GameEntry> get games => UnmodifiableListView(_entries);

  void fetch() async {
    final response =
        await http.get(Uri.parse('http://localhost:3030/library/testing'));

    if (response.statusCode == 200) {
      final lib = Library.fromBuffer(response.bodyBytes);
      update(lib);
    } else {
      throw Exception('Failed to load album');
    }
  }

  /// Updates the model with new entries from input [Library].
  void update(Library lib) {
    _entries.addAll(lib.entry);
    notifyListeners();
  }

  /// Removes all games from the model.
  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
