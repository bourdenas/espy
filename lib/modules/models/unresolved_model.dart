import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/documents/unresolved.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:shared_preferences/shared_preferences.dart';

/// Model that handles interactions with remote library data store.
class UnresolvedModel extends ChangeNotifier {
  String _userId = '';
  StreamSubscription? _subscription;

  UnresolvedEntries _unresolved = UnresolvedEntries();

  List<Unresolved> get needApproval => _unresolved.needApproval;
  List<StoreEntry> get unknown => _unresolved.unknown;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void update(String? uid) async {
    if (uid == null) {
      _userId = '';
      _unresolved = UnresolvedEntries();
      _subscription?.cancel();
      _subscription = null;
      notifyListeners();
      return;
    }

    if (uid == _userId) {
      return;
    }
    _userId = uid;

    await _subscription?.cancel();
    _loadUnresolved();
  }

  Future<void> _loadUnresolved() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedFailed = prefs.getString('${_userId}_unresolved');
    if (encodedFailed != null) {
      _unresolved = UnresolvedEntries.fromJson(
          jsonDecode(encodedFailed) as Map<String, dynamic>);
      notifyListeners();
    }

    _fetch();
  }

  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_userId}_unresolved', jsonEncode(_unresolved));
  }

  Future<void> _fetch() async {
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
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
