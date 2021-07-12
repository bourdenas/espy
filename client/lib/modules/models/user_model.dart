import 'dart:convert';

import 'package:espy/constants/urls.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class UserModel extends ChangeNotifier {
  final _googleSignIn = GoogleSignIn();
  User? _user = FirebaseAuth.instance.currentUser;
  String _steamUserId = '';
  String _gogAuthCode = '';

  get user => _user!;
  get signedIn => _user != null;

  get steamUserId => _steamUserId;
  get gogAuthCode => _gogAuthCode;

  /// Sign in user through Google authentication system.
  Future<bool> signInWithGoogle() async {
    var googleSignInAccount = await _googleSignIn.signInSilently();
    if (googleSignInAccount == null) {
      try {
        googleSignInAccount = await _googleSignIn.signIn();
      } catch (e) {
        print(e);
      }
    }
    if (googleSignInAccount == null) {
      return false;
    }

    _user = await _getUser(googleSignInAccount);
    if (_user == null) {
      return false;
    }

    await _fetchUserSettings();

    notifyListeners();
    return true;
  }

  /// Sign in user without new interaction if already authenticated.
  Future<void> signInAuthenticatedUser() async {
    final googleSignInAccount = await _googleSignIn.signInSilently();
    if (googleSignInAccount == null) {
      return;
    }

    _user = await _getUser(googleSignInAccount);
    await _fetchUserSettings();

    notifyListeners();
  }

  Future<void> signOut() async {
    _googleSignIn.disconnect();
    FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateUserInformation(
      {String steamUserId = '', String gogAuthCode = ''}) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/${_user!.uid}/settings'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'steam_user_id': steamUserId,
        'gog_auth_code': gogAuthCode,
      }),
    );

    if (response.statusCode != 200) {
      print('Failed to post updated user information:\n$response');
      return;
    }

    _steamUserId = steamUserId;
    _gogAuthCode = gogAuthCode;
    notifyListeners();
  }

  Future<void> syncLibrary() async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/${_user!.uid}/sync'),
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

  Future<void> _fetchUserSettings() async {
    if (_user == null) {
      return;
    }

    final response = await http
        .get(Uri.parse('${Urls.espyBackend}/library/${_user!.uid}/settings'));

    if (response.statusCode == 200) {
      final obj = jsonDecode(response.body);
      _steamUserId = obj['steam_user_id'];
      _gogAuthCode = obj['gog_auth_code'];
    } else {
      print('Failed to retrieve user information.');
    }
  }
}

Future<User?> _getUser(GoogleSignInAccount googleSignInAccount) async {
  final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;
  final AuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleSignInAuthentication.accessToken,
    idToken: googleSignInAuthentication.idToken,
  );

  final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
  return userCredential.user;
}
