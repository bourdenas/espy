import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/recent_entry.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

class RecentModel extends ChangeNotifier {
  String _userId = '';
  Recent _recent = Recent();

  UnmodifiableListView<RecentEntry> get recent =>
      UnmodifiableListView(_recent.entries.reversed);

  void update(UserData? userData) async {
    if (userData == null) {
      _userId = '';
      _recent = Recent();
      return;
    }

    if (userData.uid.isEmpty || userData.uid == _userId) {
      return;
    }

    _userId = userData.uid;
    _loadRecent(_userId);
  }

  Future<void> _loadRecent(String userId) async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('recent')
        .doc('library_entries')
        .withConverter<Recent>(
          fromFirestore: (snapshot, _) => Recent.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => {},
        )
        .snapshots()
        .listen((DocumentSnapshot<Recent> snapshot) {
      _recent = snapshot.data() ?? Recent();

      notifyListeners();
    });
  }
}
