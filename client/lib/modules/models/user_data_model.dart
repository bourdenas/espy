import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Model that handles user profile data.
class UserDataModel extends ChangeNotifier {
  get userData => _userData;

  get userId => _userData!.uid;
  get steamUserId => _userData != null && _userData!.keys != null
      ? _userData!.keys!.steamUserId
      : '';
  get gogAuthCode => _userData != null &&
          _userData!.keys != null &&
          _userData!.keys!.gogToken != null
      ? _userData!.keys!.gogToken!.oauthCode
      : '';

  UserDataModel() {
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _fetchUserData();
  }

  String? _userId;
  UserData? _userData;

  /// Update Firestore with user's credentials to third-party data stores.
  Future<void> setUserKeys(
      {String steamUserId = '', String gogAuthCode = ''}) async {
    _userData = UserData(
      uid: _userId!,
      keys: Keys(
        steamUserId: steamUserId,
        gogToken: GogToken(oauthCode: gogAuthCode),
      ),
      version: null,
    );

    FirebaseFirestore.instance.collection('users').doc(_userId!).update({
      'keys': {
        'steam_user_id': steamUserId,
        'gog_token': {
          'oauth_code': gogAuthCode,
        },
      },
    }).onError((error, _) => print('Failed to update user profile:$error'));
  }

  /// Initiates the library sync process to the espy backend for the user.
  Future<void> syncLibrary() async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/${_userId!}/sync'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      print('Sync successful.');
    } else {
      print('Failed to post updated user information:\n${response.statusCode}');
    }
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
