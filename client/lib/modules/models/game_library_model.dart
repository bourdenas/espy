import 'package:espy/constants/urls.dart';
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
}
