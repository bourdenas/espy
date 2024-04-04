import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/user_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, kDebugMode;
import 'package:http/http.dart' as http;

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

  /// Unlinks a storefront from the account.
  Future<void> unlink(String storefrontId) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/${_userId!}/unlink'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'storefront_id': storefrontId}),
    );

    if (response.statusCode != 200) {
      if (kDebugMode) {
        print('Failed to unlink storefront:\n${response.statusCode}');
      }
    }
  }

  /// Initiates the library sync process to the espy backend for the user.
  Future<String> syncLibrary(Keys keys) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/${_userId!}/sync'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(keys.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonObj = jsonDecode(response.body) as Map<String, dynamic>;
      final report = ReconReport.fromJson(jsonObj);
      return report.lines.join('\n');
    } else {
      return 'Failed to post updated user information:\n${response.statusCode}';
    }
  }

  Future<String> uploadLibrary(Upload titles) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/${_userId!}/upload'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(titles.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonObj = jsonDecode(response.body) as Map<String, dynamic>;
      final report = ReconReport.fromJson(jsonObj);
      return report.lines.join('\n');
    } else {
      return 'Failed to upload game titles:\n${response.statusCode}';
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
