import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/user_ratings.dart';
import 'package:flutter/material.dart' show ChangeNotifier;

class UserDataModel extends ChangeNotifier {
  String _userId = '';
  UserRatings _ratings = UserRatings(ratings: {});

  int rating(int gameId) => _ratings.ratings[gameId] ?? 0;
  void updateRating(int gameId, int rating) async {
    _ratings.ratings[gameId] = rating;

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('ratings')
        .set(_ratings.toJson());
  }

  void update(String userId) async {
    if (userId.isNotEmpty && _userId != userId) {
      _userId = userId;
      _loadUserData(userId);
    }
  }

  Future<void> _loadUserData(String userId) async {
    FirebaseFirestore.instance
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
