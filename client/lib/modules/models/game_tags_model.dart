import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_tags.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Index of tags extracted from user's library.
///
/// The index is computed on-the-fly in the client.
class GameTagsModel extends ChangeNotifier {
  Set<String> _stores = {};
  Set<String> _companies = {};
  Set<String> _collections = {};

  Map<String, List<int>> _tags = {};
  UserTags _userTags = UserTags(tags: []);
  String _userId = '';

  UnmodifiableListView<String> get stores => UnmodifiableListView(_stores);
  UnmodifiableListView<String> get companies =>
      UnmodifiableListView(_companies);
  UnmodifiableListView<String> get collections =>
      UnmodifiableListView(_collections);
  UnmodifiableListView<String> get tags => UnmodifiableListView(_tags.keys);

  List<String> userTags(int gameId) {
    return _tags.entries
        .where((e) => e.value.contains(gameId))
        .map((e) => e.key)
        .toList();
  }

  void addUserTag(String label, int gameId) async {
    _addTag(label, gameId);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userTags.toJson());
  }

  void _addTag(String label, int gameId) {
    for (final tag in _userTags.tags) {
      if (tag.name == label) {
        tag.gameIds.add(gameId);
        return;
      }
    }
    _userTags.tags.add(Tag(name: label, gameIds: [gameId]));
  }

  void removeUserTag(String label, int gameId) async {
    for (final tag in _userTags.tags) {
      if (tag.name == label) {
        tag.gameIds.remove(gameId);
      }
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userTags.toJson());
  }

  Iterable<String> filterCompanies(Iterable<String> terms) {
    return companies.where((company) => terms.every((term) =>
        company.toLowerCase().split(' ').any((word) => word.startsWith(term))));
  }

  Iterable<String> filterStores(Iterable<String> terms) {
    return stores.where(
      (store) => terms.every((term) =>
          store.toLowerCase().split(' ').any((word) => word.startsWith(term))),
    );
  }

  Iterable<String> filterCollections(Iterable<String> terms) {
    return collections.where((collection) => terms.every((term) => collection
        .toLowerCase()
        .split(' ')
        .any((word) => word.startsWith(term))));
  }

  Iterable<String> filterTags(Iterable<String> terms) {
    return tags.where(
      (tag) => terms.every((term) =>
          tag.toLowerCase().split(' ').any((word) => word.startsWith(term))),
    );
  }

  void update(String userId, List<LibraryEntry> entries) async {
    _tags.clear();
    for (final entry in entries) {
      _stores.addAll(entry.storeEntries.map((e) => e.storefront));
      _companies.addAll(entry.companies.map((company) => company));
      _collections.addAll(entry.collections.map((collection) => collection));
    }

    _userId = userId;
    await _loadUserTags(userId);
    // NOTE: notifyListeners() happens on the user tags snapshot callback.
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
      final user_tags = snapshot.data();
      if (user_tags == null) {
        notifyListeners();
        return;
      }

      _userTags = user_tags;
      for (final tag in user_tags.tags) {
        _tags[tag.name] = tag.gameIds;
      }

      notifyListeners();
    });
  }
}
