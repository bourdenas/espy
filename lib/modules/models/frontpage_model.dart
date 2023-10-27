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
    final maxPop = DateTime.now().isBefore(
            DateTime.fromMillisecondsSinceEpoch(game.releaseDate * 1000))
        ? _maxPopularityFuture
        : _maxPopularityPast;
    return max(.33333, log(game.popularity) / log(maxPop));
  }

  int _maxPopularityPast = 0;
  int _maxPopularityFuture = 0;

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
      _maxPopularityPast = _maxPopularityFuture = 0;

      for (final game in mostAnticipated) {
        _maxPopularityFuture = max(_maxPopularityFuture, game.popularity);

        final date = game.formatReleaseDate('yMMMd');
        if (_gamesByDate.containsKey(date)) {
          _gamesByDate[date]?.add(game);
        } else {
          _gamesByDate[date] = [game];
        }
      }

      for (final game in popular) {
        _maxPopularityPast = max(_maxPopularityPast, game.popularity);

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
