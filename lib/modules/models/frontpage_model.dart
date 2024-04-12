import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/frontpage.dart';
import 'package:espy/modules/documents/timeline.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class FrontpageModel extends ChangeNotifier {
  Frontpage _frontpage = const Frontpage();

  List<ReleaseEvent> get releases => _frontpage.releases;

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
