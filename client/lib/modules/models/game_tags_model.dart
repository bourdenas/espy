import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_tags.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

/// Index of tags extracted from user's library.
///
/// The index is computed on-the-fly in the client.
class GameTagsModel extends ChangeNotifier {
  Set<String> _stores = {};
  Set<String> _companies = {};
  Map<String, int> _collections = {};

  UserTags _userTags = UserTags(tags: []);
  Map<int, List<String>> _tagsByEntry = {};
  Map<String, List<int>> _entriesByTag = {};
  String _userId = '';

  UnmodifiableListView<String> get stores => UnmodifiableListView(_stores);
  UnmodifiableListView<String> get companies =>
      UnmodifiableListView(_companies);
  UnmodifiableListView<String> get collections =>
      UnmodifiableListView(_collections.entries
          .where((entry) => entry.value > 1)
          .map((entry) => entry.key)
          .toList()
        ..sort());

  UnmodifiableListView<String> get tags =>
      UnmodifiableListView(_userTags.tags.map((e) => e.name).toList()..sort());
  UnmodifiableListView<String> get tagsByPopulation {
    final list = _entriesByTag.entries
        .map((e) => MapEntry(e.key, e.value.length))
        .toList()
      ..sort((a, b) => -a.value.compareTo(b.value));
    return UnmodifiableListView(list.map((e) => e.key));
  }

  int getCollectionSize(String collection) => _collections[collection] ?? 0;

  List<String> tagsByEntry(int gameId) => _tagsByEntry[gameId] ?? [];
  List<int> entriesByTag(String tag) => _entriesByTag[tag] ?? [];

  void addUserTag(String label, int gameId) async {
    _addTag(label, gameId);

    FirebaseFirestore.instance
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
    int index = 0;
    for (final tag in _userTags.tags) {
      if (tag.name == label) {
        tag.gameIds.remove(gameId);

        if (tag.gameIds.isEmpty) {
          _userTags.tags.removeAt(index);
        }
        break;
      }
      ++index;
    }

    FirebaseFirestore.instance
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
    _collections.clear();

    for (final entry in entries) {
      _stores.addAll(entry.storeEntries.map((e) => e.storefront));
      _companies.addAll(entry.companies.map((company) => company));
      for (final collection in entry.collections) {
        _collections[collection] = (_collections[collection] ?? 0) + 1;
      }
    }

    if (userId.isNotEmpty && _userId != userId) {
      _userId = userId;
      await _loadUserTags(userId);
    }
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
      _userTags = snapshot.data() ?? UserTags(tags: []);

      _tagsByEntry.clear();
      _entriesByTag.clear();

      for (final tag in _userTags.tags) {
        for (final id in tag.gameIds) {
          var tags = _tagsByEntry[id];
          if (tags != null) {
            tags.add(tag.name);
          } else {
            _tagsByEntry[id] = [tag.name];
          }

          var entries = _entriesByTag[tag.name];
          if (entries != null) {
            entries.add(id);
          } else {
            _entriesByTag[tag.name] = [id];
          }
        }
      }
      debugPrint('🎯 updated tags snapshot');

      notifyListeners();
    });
  }
}
