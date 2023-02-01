import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:shared_preferences/shared_preferences.dart';

/// Model that handles interactions with remote library data store.
class FailedModel extends ChangeNotifier {
  FailedEntries _failed = FailedEntries();
  String userId = '';

  List<StoreEntry> get entries => _failed.entries;

  void update(UserData? userData) async {
    if (userData == null) {
      userId = '';
      _failed = FailedEntries();
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

    final encodedFailed = prefs.getString('${userId}_failed');
    if (encodedFailed != null) {
      _failed = FailedEntries.fromJson(
          jsonDecode(encodedFailed) as Map<String, dynamic>);
      notifyListeners();
    }

    _fetch();
  }

  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${userId}_failed', jsonEncode(_failed));
  }

  Future<void> _fetch() async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('games')
        .doc('failed')
        .withConverter<FailedEntries>(
          fromFirestore: (snapshot, _) =>
              FailedEntries.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .snapshots()
        .listen((DocumentSnapshot<FailedEntries> snapshot) {
      _failed = snapshot.data() ?? FailedEntries();
      notifyListeners();
      _saveLocally();
    });
  }
}
