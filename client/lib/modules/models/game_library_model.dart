import 'dart:collection';

import 'package:espy/proto/igdbapi.pb.dart';
import 'package:espy/proto/library.pb.dart';
import 'package:flutter/foundation.dart';

class GameLibraryModel extends ChangeNotifier {
  /// Internal, private state of the cart.
  final List<GameEntry> _entries = [
    GameEntry()
      ..game = (Game()
        ..name = 'XCOM 2'
        ..cover = (Cover(imageId: 'co1mvj'))),
    GameEntry()
      ..game = (Game()
        ..name = 'Stellaris'
        ..cover = (Cover(imageId: 'co1r75'))),
    GameEntry()
      ..game = (Game()
        ..name = 'Heroes 3 HD'
        ..cover = (Cover(imageId: 'co1hv2'))),
    GameEntry()
      ..game = (Game()
        ..name = 'Skyrim'
        ..cover = (Cover(imageId: 'co1vco'))),
    GameEntry()
      ..game = (Game()
        ..name = 'Divinity: Original Sin'
        ..cover = (Cover(imageId: 'co2axn'))),
    GameEntry()
      ..game = (Game()
        ..name = 'Monkey Island 2'
        ..cover = (Cover(imageId: 'co2562'))),
  ];

  UnmodifiableListView<GameEntry> get games => UnmodifiableListView(_entries);

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
