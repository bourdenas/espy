import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/frontpage.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/calendar.dart';
import 'package:espy/modules/models/custom_view_model.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FrontpageModel extends ChangeNotifier {
  Frontpage _frontpage = const Frontpage();

  Frontpage get frontpage => _frontpage;
  List<ReleaseEvent> get timeline => _frontpage.timeline;

  List<SlateInfo> get slates => [
        SlateInfo(
          'Releasing today',
          _frontpage.todayReleases
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) {
            context.read<CustomViewModel>().digests = _frontpage.todayReleases;
            context.pushNamed('view');
          },
        ),
        SlateInfo(
          'Recent releases',
          _frontpage.recentReleases
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) {
            context.read<CustomViewModel>().digests = _frontpage.recentReleases;
            context.pushNamed('view');
          },
        ),
        SlateInfo(
          'Upcoming releases',
          _frontpage.upcomingReleases
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) {
            context.read<CustomViewModel>().digests =
                _frontpage.upcomingReleases;
            context.pushNamed('view');
          },
        ),
        SlateInfo(
          'Most anticipated',
          _frontpage.hyped.map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) {
            context.read<CustomViewModel>().digests = _frontpage.hyped;
            context.pushNamed('view');
          },
        ),
      ];

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
      notifyListeners();
    });
  }

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
}
