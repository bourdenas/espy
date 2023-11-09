import 'dart:collection';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/timeline.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class FrontpageModel extends ChangeNotifier {
  Timeline _frontpage = const Timeline();

  List<GameDigest> get upcoming => _frontpage.upcoming;
  List<GameDigest> get recent => _frontpage.recent;

  List<GameDigest> gamesByDate(String date) => _gamesByDate[date] ?? [];
  final Map<String, List<GameDigest>> _gamesByDate = {};

  List<(DateTime, List<GameDigest>)> get games => _games;
  final List<(DateTime, List<GameDigest>)> _games = [];

  double normalizePopularity(GameDigest game) {
    final maxPop = DateTime.now().isBefore(
            DateTime.fromMillisecondsSinceEpoch(game.releaseDate * 1000))
        ? _maxPopularityFuture
        : _maxPopularityPast;
    return max(.5, log(game.popularity) / log(maxPop));
  }

  int _maxPopularityPast = 0;
  int _maxPopularityFuture = 0;

  Future<void> load() async {
    FirebaseFirestore.instance
        .collection('espy')
        .doc('timeline')
        .withConverter<Timeline>(
          fromFirestore: (snapshot, _) => Timeline.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => {},
        )
        .snapshots()
        .listen((DocumentSnapshot<Timeline> snapshot) {
      _frontpage = snapshot.data() ?? const Timeline();
      _gamesByDate.clear();
      _maxPopularityPast = _maxPopularityFuture = 0;

      for (final game in upcoming) {
        _maxPopularityFuture = max(_maxPopularityFuture, game.popularity);

        final date = game.formatReleaseDate('yMMMd');
        _gamesByDate.putIfAbsent(date, () => []).add(game);
      }

      for (final game in recent) {
        _maxPopularityPast = max(_maxPopularityPast, game.popularity);

        final date = game.formatReleaseDate('yMMMd');
        _gamesByDate.putIfAbsent(date, () => []).add(game);
      }

      SplayTreeMap<DateTime, List<GameDigest>> games = SplayTreeMap();
      for (final game in [recent, upcoming].expand((e) => e)) {
        games.putIfAbsent(game.release, () => []).add(game);
      }
      _games.addAll(games.entries.map((e) => (e.key, e.value)));

      notifyListeners();
    });
  }
}
