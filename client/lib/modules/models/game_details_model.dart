import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class GameDetailsModel extends ChangeNotifier {
  String _userId = '';

  void update(String userId) async {
    _userId = userId;
  }

  void postDetails(LibraryEntry entry) async {
    entry.userData.tags.sort();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('library')
        .doc(entry.id.toString())
        .set(entry.toJson());
  }
}
