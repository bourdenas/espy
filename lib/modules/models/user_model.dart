import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model that handles user profile data.
class UserModel extends ChangeNotifier {
  String? _userId;

  String? get userId => _userId;

  bool get isSignedIn => _userId != null;
  bool get isNotSignedIn => _userId == null;

  UserModel() {
    login();
  }

  void login() async {
    if (FirebaseAuth.instance.currentUser == null) {
      return;
    }

    _userId = FirebaseAuth.instance.currentUser?.uid;
    notifyListeners();
  }

  void logout() {
    FirebaseAuth.instance.signOut();
    _userId = null;
    notifyListeners();
  }

  Future<UserData?> fetchUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .withConverter<UserData>(
          fromFirestore: (snapshot, _) => UserData.fromJson(snapshot.data()!),
          toFirestore: (userData, _) => userData.toJson(),
        )
        .get();

    return doc.data();
  }
}
