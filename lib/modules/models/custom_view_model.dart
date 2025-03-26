import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model that represents what is visible in a library screen.
class CustomViewModel extends ChangeNotifier {
  List<LibraryEntry> get games => _games;
  int get length => _games.length;

  set games(List<LibraryEntry> games) {
    _games = games;
    notifyListeners();
  }

  set digests(Iterable<GameDigest> digests) {
    games =
        digests.map((digest) => LibraryEntry.fromGameDigest(digest)).toList();
  }

  void clear() {
    _games.clear();
    notifyListeners();
  }

  List<LibraryEntry> _games = [];
}
