import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserModel extends ChangeNotifier {
  final _googleSignIn = GoogleSignIn();
  User? _user = FirebaseAuth.instance.currentUser;

  get user => _user!;
  get signedIn => _user != null;

  /// Sign in user through Google authentication system.
  Future<bool> signInWithGoogle() async {
    var googleSignInAccount = await _googleSignIn.signInSilently();
    if (googleSignInAccount == null) {
      try {
        googleSignInAccount = await _googleSignIn.signIn();
      } catch (e) {
        print('$e');
      }
    }
    if (googleSignInAccount == null) {
      return false;
    }

    _user = await _getUser(googleSignInAccount);
    if (_user == null) {
      return false;
    }

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
    notifyListeners();
  }

  Future<void> signOut() async {
    _googleSignIn.disconnect();
    FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
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
}
