import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:shared_preferences/shared_preferences.dart';

/// Model that handles interactions with remote library data store.
class UserLibraryModel extends ChangeNotifier {
  String _userId = '';
  StreamSubscription? _subscription;

  // The user library.
  Library _library = const Library();

  bool get isNotEmpty => _library.entries.isNotEmpty;
  Iterable<LibraryEntry> get all => _library.entries;
  Iterable<LibraryEntry> get entries => _library.entries
      .where((e) => e.digest.isStandaloneGame || e.digest.isExpansion);

  set library(Library lib) {
    lib.entries.sort((a, b) => -a.addedDate.compareTo(b.addedDate));
    _library = lib;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void update(String? uid) async {
    if (uid == null) {
      _userId = '';
      _library = const Library();
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
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedLibrary = prefs.getString('${_userId}_library');
    if (encodedLibrary != null) {
      try {
        library = Library.fromJson(
            jsonDecode(encodedLibrary) as Map<String, dynamic>);
        notifyListeners();
      } catch (_) {}
    }

    _fetch();
  }

  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_userId}_library', jsonEncode(_library));
  }

  Future<void> _fetch() async {
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('games')
        .doc('library')
        .withConverter<Library>(
          fromFirestore: (snapshot, _) => Library.fromJson(snapshot.data()!),
          toFirestore: (library, _) => library.toJson(),
        )
        .snapshots()
        .listen((DocumentSnapshot<Library> snapshot) {
      library = snapshot.data() ?? const Library();
      notifyListeners();
      _saveLocally();
    });
  }
}
