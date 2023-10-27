import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/frontpage.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class FrontpageModel extends ChangeNotifier {
  Frontpage _frontpage = const Frontpage();

  List<GameDigest> get upcoming => _frontpage.upcoming;
  List<GameDigest> get mostAnticipated => _frontpage.mostAnticipated;
  List<GameDigest> get recent => _frontpage.recent;
  List<GameDigest> get popular => _frontpage.popular;
  List<GameDigest> get criticallyAcclaimed => _frontpage.criticallyAcclaimed;

  List<GameDigest> gamesByDate(String date) => _gamesByDate[date] ?? [];
  final Map<String, List<GameDigest>> _gamesByDate = {};

  double normalizePopularity(GameDigest game) {
    return max(.33333, log(game.popularity) / log(_maxPopularity));
  }

  int _maxPopularity = 0;

  Future<void> load() async {
    FirebaseFirestore.instance
        .collection('espy')
        .doc('frontpage')
        .withConverter<Frontpage>(
          fromFirestore: (snapshot, _) => Frontpage.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => {},
        )
        .snapshots()
        .listen((DocumentSnapshot<Frontpage> snapshot) {
      _frontpage = snapshot.data() ?? const Frontpage();
      _gamesByDate.clear();
      _maxPopularity = 0;

      for (final game in mostAnticipated) {
        _maxPopularity = max(_maxPopularity, game.popularity);

        final date = game.formatReleaseDate('yMMMd');
        if (_gamesByDate.containsKey(date)) {
          _gamesByDate[date]?.add(game);
        } else {
          _gamesByDate[date] = [game];
        }
      }

      notifyListeners();
    });
  }
}
