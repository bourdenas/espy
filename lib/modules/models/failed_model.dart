import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/documents/unresolved.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:shared_preferences/shared_preferences.dart';

/// Model that handles interactions with remote library data store.
class UnresolvedModel extends ChangeNotifier {
  UnresolvedEntries _unresolved = UnresolvedEntries();
  String userId = '';

  List<Unresolved> get needApproval => _unresolved.needApproval;
  List<StoreEntry> get unknown => _unresolved.unknown;

  void update(UserData? userData) async {
    if (userData == null) {
      userId = '';
      _unresolved = UnresolvedEntries();
      notifyListeners();
      return;
    }

    if (userData.uid == userId) {
      return;
    }
    userId = userData.uid;

    await _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedFailed = prefs.getString('${userId}_unresolved');
    if (encodedFailed != null) {
      _unresolved = UnresolvedEntries.fromJson(
          jsonDecode(encodedFailed) as Map<String, dynamic>);
      notifyListeners();
    }

    _fetch();
  }

  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${userId}_unresolved', jsonEncode(_unresolved));
  }

  Future<void> _fetch() async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('games')
        .doc('unresolved')
        .withConverter<UnresolvedEntries>(
          fromFirestore: (snapshot, _) =>
              UnresolvedEntries.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .snapshots()
        .listen((DocumentSnapshot<UnresolvedEntries> snapshot) {
      _unresolved = snapshot.data() ?? UnresolvedEntries();
      notifyListeners();
      _saveLocally();
    });
  }
}
