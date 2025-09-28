import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/user_ratings.dart';
import 'package:flutter/material.dart' show ChangeNotifier;

class UserDataModel extends ChangeNotifier {
  String _userId = '';
  StreamSubscription? _subscription;
  UserRatings _ratings = UserRatings(ratings: {});

  int rating(int gameId) => _ratings.ratings[gameId] ?? 0;

  void updateRating(int gameId, int rating) async {
    if (rating != 0) {
      _ratings.ratings[gameId] = rating;
    } else {
      _ratings.ratings.remove(gameId);
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('ratings')
        .set(_ratings.toJson());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void update(String? uid) async {
    if (uid == null) {
      _userId = '';
      _ratings = UserRatings(ratings: {});
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
    _loadUserData(_userId);
  }

  Future<void> _loadUserData(String userId) async {
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('user_data')
        .doc('ratings')
        .withConverter<UserRatings>(
          fromFirestore: (snapshot, _) =>
              UserRatings.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .snapshots()
        .listen((DocumentSnapshot<UserRatings> snapshot) {
      _ratings = snapshot.data() ?? _ratings;
      notifyListeners();
    });
  }
}
