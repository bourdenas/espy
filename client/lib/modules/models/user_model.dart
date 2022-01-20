import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/material.dart';

/// Model that manages user authentication & identity.
class UserModel extends ChangeNotifier {
  User? _user;
  StreamSubscription<User?>? _userSubscription;

  get user => _user;

  UserModel() {
    _userSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    if (_userSubscription != null) {
      _userSubscription!.cancel();
    }
    super.dispose();
  }
}
