import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/timeline.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:intl/intl.dart';

class TimelineModel extends ChangeNotifier {
  Timeline _frontpage = const Timeline();

  List<GameDigest> get upcoming => _frontpage.upcoming;
  List<GameDigest> get recent => _frontpage.recent;

  List<(DateTime, List<GameDigest>)> get games => _games;
  final List<(DateTime, List<GameDigest>)> _games = [];

  double normalizePopularity(GameDigest game) {
    var maxPop = DateTime.now().isBefore(
            DateTime.fromMillisecondsSinceEpoch(game.releaseDate * 1000))
        ? _maxPopularityFuture
        : _maxPopularityPast;
    maxPop = maxPop > 0 ? maxPop : 1;
    return max(.5, log(game.scores.popularity ?? 0) / log(maxPop));
  }

  int _maxPopularityPast = 0;
  int _maxPopularityFuture = 0;

  Future<List<(DateTime, GameDigest)>> gamesIn(String year) async {
    final doc = await FirebaseFirestore.instance
        .collection('espy')
        .doc(year)
        .withConverter<Timeline>(
          fromFirestore: (snapshot, _) => Timeline.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => {},
        )
        .get();

    final timeline = doc.data() ?? const Timeline();

    List<(DateTime, GameDigest)> games = [];
    for (final game in [timeline.recent, timeline.upcoming].expand((e) => e)) {
      games.add((game.release, game));
    }

    return games;
  }

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
      _maxPopularityPast = _maxPopularityFuture = 0;

      Map<String, List<GameDigest>> games = {};
      for (final game in recent) {
        _maxPopularityPast =
            max(_maxPopularityPast, game.scores.popularity ?? 0);
        games.putIfAbsent(game.releaseDay, () => []).add(game);
      }
      for (final game in upcoming) {
        _maxPopularityFuture =
            max(_maxPopularityFuture, game.scores.popularity ?? 0);
        games.putIfAbsent(game.releaseDay, () => []).add(game);
      }

      _games.addAll(games.entries
          .map((e) => (DateFormat('yMMMd').parse(e.key), e.value)));
      _games.sort((a, b) => a.$1.compareTo(b.$1));

      notifyListeners();
    });
  }
}
