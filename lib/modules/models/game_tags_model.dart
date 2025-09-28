import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_annotations.dart';
import 'package:espy/modules/models/library_index_model.dart';
import 'package:espy/modules/models/tags/manual_genre_manager.dart';
import 'package:espy/modules/models/tags/label_manager.dart';
import 'package:espy/modules/models/tags/user_tag_manager.dart';
import 'package:flutter/material.dart' show ChangeNotifier;

/// Index of tags extracted from user's library.
///
/// The index is computed on-the-fly in the client.
class GameTagsModel extends ChangeNotifier {
  String _userId = '';
  StreamSubscription? _subscription;

  late LabelManager _storesManager;
  late LabelManager _developersManager;
  late LabelManager _publishersManager;
  late LabelManager _collectionsManager;
  late LabelManager _franchisesManager;
  late LabelManager _genresManager;
  late LabelManager _keywordsManager;
  ManualGenreManager _manualGenresManager =
      ManualGenreManager(UserAnnotations(), (_) => null);
  UserTagManager _userTagsManager =
      UserTagManager('', UserAnnotations(), (_) => null);

  LabelManager get stores => _storesManager;
  LabelManager get developers => _developersManager;
  LabelManager get publishers => _publishersManager;
  LabelManager get collections => _collectionsManager;
  LabelManager get franchises => _franchisesManager;
  LabelManager get genres => _genresManager;
  LabelManager get keywords => _keywordsManager;
  ManualGenreManager get manualGenres => _manualGenresManager;
  UserTagManager get userTags => _userTagsManager;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void update(
    String? uid,
    LibraryIndexModel indexModel,
  ) async {
    _indexModel = indexModel;

    final entries = indexModel.entries;
    _storesManager = LabelManager(
      entries,
      (entry) => entry.storeEntries.map((store) => store.storefront),
    );
    _developersManager = LabelManager(
      entries,
      (entry) => entry.digest.developers,
    );
    _publishersManager = LabelManager(
      entries,
      (entry) => entry.digest.publishers,
    );
    _collectionsManager = LabelManager(
      entries,
      (entry) => entry.digest.collections,
    );
    _franchisesManager = LabelManager(
      entries,
      (entry) => entry.digest.franchises,
    );
    _genresManager = LabelManager(
      entries,
      (entry) => entry.digest.espyGenres,
      createEmpty: true,
    );
    _keywordsManager = LabelManager(
      entries,
      (entry) => entry.digest.keywords,
    );

    if (uid == null) {
      _userId = '';
      _subscription?.cancel();
      _subscription = null;
      notifyListeners();
      return;
    }

    if (_userId == uid) {
      return;
    }
    _userId = uid;

    await _subscription?.cancel();
    _loadUserTags(uid);
  }

  Future<void> _loadUserTags(String userId) async {
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('user_data')
        .doc('tags')
        .withConverter<UserAnnotations>(
          fromFirestore: (snapshot, _) =>
              UserAnnotations.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .snapshots()
        .listen((DocumentSnapshot<UserAnnotations> snapshot) {
      final userTags = snapshot.data() ?? UserAnnotations();
      _manualGenresManager = ManualGenreManager(userTags, _getEntryById)
        ..build();
      _userTagsManager = UserTagManager(userId, userTags, _getEntryById)
        ..build();
      notifyListeners();
    });
  }

  late LibraryIndexModel _indexModel;
  LibraryEntry? _getEntryById(int id) => _indexModel.getEntryById(id);
}
