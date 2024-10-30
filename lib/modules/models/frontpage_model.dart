import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/frontpage.dart';
import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/timeline.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:go_router/go_router.dart';

class FrontpageModel extends ChangeNotifier {
  Frontpage _frontpage = const Frontpage();

  List<ReleaseEvent> get timeline => _frontpage.timeline;
  List<SlateInfo> get slates => [
        SlateInfo(
          'Releasing today',
          _frontpage.todayReleases
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) => context.goNamed('today'),
        ),
        SlateInfo(
          'Recent releases',
          _frontpage.recentReleases
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) => context.goNamed('recent'),
        ),
        SlateInfo(
          'Upcoming releases',
          _frontpage.upcomingReleases
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) => context.goNamed('upcoming'),
        ),
        SlateInfo(
          'Most anticipated',
          _frontpage.hyped.map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) => context.goNamed('hyped'),
        ),
      ];

  List<GameDigest> get todayReleases => _frontpage.todayReleases;
  List<GameDigest> get upcomingReleases => _frontpage.upcomingReleases;
  List<GameDigest> get recentReleases => _frontpage.recentReleases;
  List<GameDigest> get hyped => _frontpage.hyped;

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
}
