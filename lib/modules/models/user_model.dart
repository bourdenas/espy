import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, kDebugMode;

/// Model that handles user profile data.
class UserModel extends ChangeNotifier {
  get userData => _userData;

  String get userId => _userData?.uid ?? '';
  String get gogAuthCode => _userData?.keys?.gogAuthCode ?? '';
  String get steamUserId => _userData?.keys?.steamUserId ?? '';

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
    await _fetchUserData();
    notifyListeners();
  }

  void logout() {
    FirebaseAuth.instance.signOut();
    _userId = null;
    _userData = null;
    notifyListeners();
  }

  String? _userId;
  UserData? _userData;

  /// Update Firestore with user's credentials to third-party data stores.
  Future<void> setUserKeys(Keys keys) async {
    if (gogAuthCode != keys.gogAuthCode || steamUserId != keys.steamUserId) {
      FirebaseFirestore.instance.collection('users').doc(_userId!).update({
        'keys': {
          'gog_auth_code': keys.gogAuthCode,
          'steam_user_id': keys.steamUserId,
        },
      }).onError((error, _) {
        if (kDebugMode) {
          print(error);
        }
      });
    }

    _userData = UserData(
      uid: _userId!,
      keys: keys,
      version: _userData!.version,
    );
  }

  /// Retrieves UserData from Firestore.
  Future<void> _fetchUserData() async {
    if (_userId == null) {
      return;
    }

    _userDataSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId!)
        .withConverter<UserData>(
          fromFirestore: (snapshot, _) => UserData.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .snapshots()
        .listen((data) async {
      UserData? userData = data.data();

      if (userData == null) {
        // Create new user entry.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId!)
            .set(UserData(uid: _userId!, keys: null, version: null).toJson());
        return;
      }

      _userData = userData;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    if (_userDataSubscription != null) {
      _userDataSubscription!.cancel();
    }
    super.dispose();
  }

  StreamSubscription<DocumentSnapshot<UserData>>? _userDataSubscription;
}
