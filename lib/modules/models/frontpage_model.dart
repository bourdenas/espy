import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/frontpage.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/timeline.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:go_router/go_router.dart';

class FrontpageModel extends ChangeNotifier {
  Frontpage _frontpage = const Frontpage();

  Frontpage get frontpage => _frontpage;
  List<ReleaseEvent> get timeline => _frontpage.timeline;
  List<SlateInfo> get slates => [
        SlateInfo(
          'Releasing today',
          _frontpage.todayReleases
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) => context.pushNamed(
            'view',
            pathParameters: {
              'label': 'today',
              'year': '2024',
            },
          ),
        ),
        SlateInfo(
          'Recent releases',
          _frontpage.recentReleases
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) => context.pushNamed(
            'view',
            pathParameters: {
              'label': 'recent',
              'year': '2024',
            },
          ),
        ),
        SlateInfo(
          'Upcoming releases',
          _frontpage.upcomingReleases
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) => context.pushNamed(
            'view',
            pathParameters: {
              'label': 'upcoming',
              'year': '2024',
            },
          ),
        ),
        SlateInfo(
          'Most anticipated',
          _frontpage.hyped.map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) => context.pushNamed(
            'view',
            pathParameters: {
              'label': 'hyped',
              'year': '2024',
            },
          ),
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
}
