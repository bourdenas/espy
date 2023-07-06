import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_tags.dart';
import 'package:espy/modules/models/tags/genre_tag_manager.dart';
import 'package:espy/modules/models/tags/label_manager.dart';
import 'package:espy/modules/models/tags/user_tag_manager.dart';
import 'package:flutter/material.dart' show ChangeNotifier;

/// Index of tags extracted from user's library.
///
/// The index is computed on-the-fly in the client.
class GameTagsModel extends ChangeNotifier {
  String _userId = '';

  LabelManager _storesManager = LabelManager([]);
  LabelManager _developersManager = LabelManager([]);
  LabelManager _publishersManager = LabelManager([]);
  LabelManager _collectionsManager = LabelManager([]);
  LabelManager _franchisesManager = LabelManager([]);
  LabelManager _genresManager = LabelManager([]);
  LabelManager _keywordsManager = LabelManager([]);
  GenreTagManager _genreTagsManager = GenreTagManager('', UserTags());
  UserTagManager _userTagsManager = UserTagManager('', UserTags());

  LabelManager get stores => _storesManager;
  LabelManager get developers => _developersManager;
  LabelManager get publishers => _publishersManager;
  LabelManager get collections => _collectionsManager;
  LabelManager get franchises => _franchisesManager;
  LabelManager get genres => _genresManager;
  LabelManager get keywords => _keywordsManager;
  GenreTagManager get genreTags => _genreTagsManager;
  UserTagManager get userTags => _userTagsManager;

  void update(
    String userId,
    List<LibraryEntry> entries,
    List<LibraryEntry> wishlist,
  ) async {
    final allEntries = entries + wishlist;
    _storesManager = LabelManager(allEntries,
        (entry) => entry.storeEntries.map((store) => store.storefront));
    _developersManager =
        LabelManager(allEntries, (entry) => entry.digest.developers);
    _publishersManager =
        LabelManager(allEntries, (entry) => entry.digest.publishers);
    _collectionsManager =
        LabelManager(allEntries, (entry) => entry.digest.collections);
    _franchisesManager =
        LabelManager(allEntries, (entry) => entry.digest.franchises);
    _genresManager = LabelManager(allEntries, (entry) => entry.digest.genres);
    _keywordsManager =
        LabelManager(allEntries, (entry) => entry.digest.keywords);

    if (userId.isNotEmpty && _userId != userId) {
      _userId = userId;
      _loadUserTags(userId);
    }
  }

  Future<void> _loadUserTags(String userId) async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('user_data')
        .doc('tags')
        .withConverter<UserTags>(
          fromFirestore: (snapshot, _) => UserTags.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .snapshots()
        .listen((DocumentSnapshot<UserTags> snapshot) {
      final userTags = snapshot.data() ?? UserTags();
      _genreTagsManager = GenreTagManager(_userId, userTags)..build();
      _userTagsManager = UserTagManager(_userId, userTags)..build();
      notifyListeners();
    });
  }
}
