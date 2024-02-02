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

  List<ReleaseDay> get releases => _releases;
  final List<ReleaseDay> _releases = [];

  double highlightScore(GameDigest game) {
    final isReleased = DateTime.now()
        .isAfter(DateTime.fromMillisecondsSinceEpoch(game.releaseDate * 1000));
    var maxScore = isReleased ? _maxScorePast : _maxScoreFuture;
    maxScore = maxScore > 0 ? maxScore : 1;
    return isReleased
        ? scale(game.scores.metacritic)
        : scaleFuture(game.scores.popularity);
  }

  double scale(int? score) {
    return switch (score) {
      int x when x >= 95 => 1,
      int x when x >= 90 => .9,
      int x when x >= 80 => .8,
      int x when x >= 70 => .7,
      int x when x >= 60 => .6,
      _ => .5,
    };
  }

  double scaleFuture(int? popularity) {
    return switch (popularity) {
      int x when x >= 100 => 1,
      int x when x >= 50 => .9,
      int x when x >= 30 => .8,
      int x when x >= 10 => .7,
      int x when x >= 3 => .6,
      _ => .5,
    };
  }

  int _maxScorePast = 0;
  int _maxScoreFuture = 0;

  Future<List<(DateTime, GameDigest)>> gamesIn(String year) async {
    final cache = _gamesInYear[year];
    if (cache != null) {
      return cache;
    }

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
    _gamesInYear[year] = games;

    return games;
  }

  final Map<String, List<(DateTime, GameDigest)>> _gamesInYear = {};

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
      _maxScorePast = _maxScoreFuture = 0;
      _releases.clear();

      Map<String, List<GameDigest>> games = {};
      for (final game in recent) {
        _maxScorePast = max(_maxScorePast, game.scores.metacritic ?? 0);
        games.putIfAbsent(game.releaseDay, () => []).add(game);
      }
      for (final game in upcoming) {
        _maxScoreFuture = max(_maxScoreFuture, game.scores.popularity ?? 0);
        games.putIfAbsent(game.releaseDay, () => []).add(game);
      }

      _releases.addAll(games.entries
          .map((e) => ReleaseDay(DateFormat('yMMMd').parse(e.key), e.value)));
      _releases.sort((a, b) => -a.date.compareTo(b.date));

      notifyListeners();
    });
  }
}

class ReleaseDay {
  ReleaseDay(this._date, this._games);

  final DateTime _date;
  final List<GameDigest> _games;

  DateTime get date => _date;
  Iterable<GameDigest> get games {
    return _games
      ..sort(
        (a, b) {
          final criticOrdering =
              (a.scores.metacritic ?? 0).compareTo(b.scores.metacritic ?? 0);
          return criticOrdering == 0 && (a.scores.metacritic ?? 0) == 0
              ? -(a.scores.popularity ?? 0).compareTo(b.scores.popularity ?? 0)
              : -criticOrdering;
        },
      );
  }
}
