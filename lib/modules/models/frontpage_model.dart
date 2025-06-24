import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/frontpage.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/calendar.dart';
import 'package:espy/modules/models/home_slates_model.dart';
import 'package:espy/modules/models/library_view_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FrontpageModel extends ChangeNotifier {
  Frontpage _frontpage = const Frontpage();

  Frontpage get frontpage => _frontpage;
  List<ReleaseEvent> get timeline => _frontpage.timeline;

  List<SlateInfo> get slates => [
        SlateInfo(
          'Releasing Today',
          _frontpage.todayReleases
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) {
            context
                .read<LibraryViewModel>()
                .add('today', _frontpage.todayReleases);
            context.pushNamed(
              'games',
              queryParameters: {'title': 'Releasing Today', 'view': 'today'},
            );
          },
        ),
        SlateInfo(
          'Recent Releases',
          _frontpage.recentReleases
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) {
            context
                .read<LibraryViewModel>()
                .add('recent', _frontpage.recentReleases);
            context.pushNamed(
              'games',
              queryParameters: {'title': 'Recent Releases', 'view': 'recent'},
            );
          },
        ),
        SlateInfo(
          'Upcoming Releases',
          _frontpage.upcomingReleases
              .map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) {
            context
                .read<LibraryViewModel>()
                .add('upcoming', _frontpage.upcomingReleases);
            context.pushNamed(
              'games',
              queryParameters: {
                'title': 'Upcoming Releases',
                'view': 'upcoming'
              },
            );
          },
        ),
        SlateInfo(
          'Most Anticipated',
          _frontpage.hyped.map((digest) => LibraryEntry.fromGameDigest(digest)),
          (context) {
            context.read<LibraryViewModel>().add('hyped', _frontpage.hyped);
            context.pushNamed(
              'games',
              queryParameters: {'title': 'Most Anticipated', 'view': 'hyped'},
            );
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
      _frontpage.recentReleases
          .sort((l, r) => r.prominence.compareTo(l.prominence));
      notifyListeners();
    });
  }
}
