import 'package:cloud_firestore/cloud_firestore.dart';
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

    await _fetchUserProfile();

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
    await _fetchUserProfile();

    notifyListeners();
  }

  Future<void> signOut() async {
    _googleSignIn.disconnect();
    FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateUserProfile(
      {String steamUserId = '', String gogAuthCode = ''}) async {
    _steamUserId = steamUserId;
    _gogAuthCode = gogAuthCode;

    FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
      'keys': {
        'steam_user_id': steamUserId,
        'gog_token': {
          'oauth_code': gogAuthCode,
        },
      },
    }).onError((error, _) => print('Failed to update user profile:$error'));
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

  Future<void> _fetchUserProfile() async {
    if (_user == null) {
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();

    final doc = snapshot.data();
    if (doc == null) {
      // Create new user entry.
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'uid': _user!.uid,
      });
      return;
    }

    if (doc['keys'] != null) {
      _steamUserId = doc['keys']['steam_user_id'];
      if (doc['keys']['gog_token'] != null) {
        _gogAuthCode = doc['keys']['gog_token']['oauth_code'];
      }
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
