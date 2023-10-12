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
      print('read frontpage');
      _frontpage = snapshot.data() ?? const Frontpage();

      notifyListeners();
    });
  }
}
