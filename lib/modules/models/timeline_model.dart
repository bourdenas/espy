import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/timeline.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class TimelineModel extends ChangeNotifier {
  Timeline _timeline = const Timeline();

  List<ReleaseEvent> get releases => _timeline.releases;

  double highlightScore(GameDigest game) {
    return game.isReleased
        ? _scale(game.scores.espyScore)
        : _scaleFuture(game.scores.hype);
  }

  double _scale(int? score) => switch (score) {
        int x when x >= 95 => 1,
        int x when x >= 90 => .9,
        int x when x >= 80 => .8,
        int x when x >= 70 => .7,
        int x when x >= 60 => .6,
        _ => .5,
      };

  double _scaleFuture(int? popularity) => switch (popularity) {
        int x when x >= 100 => 1,
        int x when x >= 50 => .9,
        int x when x >= 30 => .8,
        int x when x >= 10 => .7,
        int x when x >= 3 => .6,
        _ => .5,
      };

  Future<AnnualReviewDoc> gamesIn(String year) async {
    final cache = _annualReviews[year];
    if (cache != null) {
      return cache;
    }

    final doc = await FirebaseFirestore.instance
        .collection('espy')
        .doc(year)
        .withConverter<AnnualReviewDoc>(
          fromFirestore: (snapshot, _) =>
              AnnualReviewDoc.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => {},
        )
        .get();

    final review = doc.data() ?? const AnnualReviewDoc();
    _annualReviews[year] = review;

    return review;
  }

  final Map<String, AnnualReviewDoc> _annualReviews = {};

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
      _timeline = snapshot.data() ?? const Timeline();
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
