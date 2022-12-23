import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_tags.dart';
import 'package:flutter/material.dart'
    show ChangeNotifier, Colors, MaterialColor;

/// Index of tags extracted from user's library.
///
/// The index is computed on-the-fly in the client.
class GameTagsModel extends ChangeNotifier {
  // System defined tags.
  Set<String> _stores = {};
  Set<String> _companies = {};
  Map<String, int> _collections = {};

  // User defined tags and generated indices for quick access.
  UserTags _userTags = UserTags();

  Map<int, List<UserTag>> _entryToTags = {};
  Map<String, List<int>> _tagToEntries = {};
  Map<String, int> _tagToCluster = {};
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

  UnmodifiableListView<UserTag> get tags =>
      UnmodifiableListView(_tagToCluster.entries
          .map((entry) => UserTag(name: entry.key, clusterId: entry.value))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name)));
  UnmodifiableListView<String> get tagsByPopulation {
    final list = _tagToEntries.entries
        .map((e) => MapEntry(e.key, e.value.length))
        .toList()
      ..sort((a, b) => -a.value.compareTo(b.value));
    return UnmodifiableListView(list.map((e) => e.key));
  }

  int getCollectionSize(String collection) => _collections[collection] ?? 0;

  List<UserTag> tagsByEntry(int gameId) => _entryToTags[gameId] ?? [];
  List<int> entriesByTag(String tag) => _tagToEntries[tag] ?? [];
  UserTag tagByName(String name) =>
      UserTag(name: name, clusterId: _tagToCluster[name] ?? 0);

  void addUserTag(UserTag tag, int gameId) async {
    _addTag(tag, gameId);

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userTags.toJson());
  }

  void _addTag(UserTag userTag, int gameId) {
    final cl = _userTags.classes[userTag._clusterId];

    for (final tag in cl.tags) {
      if (tag.name == userTag.name) {
        tag.gameIds.add(gameId);
        return;
      }
    }

    // New Tag, create new Tag in the class.
    cl.tags.add(
      Tag(
        name: userTag.name,
        gameIds: [gameId],
      ),
    );
  }

  void moveUserTagCluster(UserTag userTag) async {
    final cl = _userTags.classes[userTag._clusterId];
    final newCluster = (userTag._clusterId + 1) % UserTag._tagClusters.length;

    for (var i = 0; i < cl.tags.length; ++i) {
      final tag = cl.tags[i];
      if (tag.name == userTag.name) {
        _userTags.classes[newCluster].tags.add(tag);
        cl.tags.removeAt(i);
        break;
      }
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userTags.toJson());
  }

  void removeUserTag(UserTag userTag, int gameId) async {
    for (final cl in _userTags.classes) {
      int index = 0;
      for (final tag in cl.tags) {
        if (tag.name == userTag.name) {
          tag.gameIds.remove(gameId);

          if (tag.gameIds.isEmpty) {
            cl.tags.removeAt(index);
          }
          break;
        }
        ++index;
      }
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userTags.toJson());
  }

  Iterable<String> filterStores(Iterable<String> terms) {
    return stores.where(
      (store) => terms.every((term) =>
          store.toLowerCase().split(' ').any((word) => word.startsWith(term))),
    );
  }

  Iterable<String> filterCompanies(Iterable<String> terms) {
    return companies.where((company) => terms.every((term) =>
        company.toLowerCase().split(' ').any((word) => word.startsWith(term))));
  }

  Iterable<String> filterCompaniesExact(Iterable<String> terms) {
    return companies.where((company) => terms.every((term) =>
        company.toLowerCase().split(' ').any((word) => word == term)));
  }

  Iterable<String> filterCollections(Iterable<String> terms) {
    return collections.where((collection) => terms.every((term) => collection
        .toLowerCase()
        .split(' ')
        .any((word) => word.startsWith(term))));
  }

  Iterable<String> filterCollectionsExact(Iterable<String> terms) {
    return collections.where((collection) => terms.every((term) =>
        collection.toLowerCase().split(' ').any((word) => word == term)));
  }

  Iterable<UserTag> filterTags(Iterable<String> terms) {
    return tags.where(
      (tag) => terms.every((term) => tag.name
          .toLowerCase()
          .split(' ')
          .any((word) => word.startsWith(term))),
    );
  }

  Iterable<UserTag> filterTagsExact(Iterable<String> terms) {
    return tags.where(
      (tag) => terms.every((term) =>
          tag.name.toLowerCase().split(' ').any((word) => word == term)),
    );
  }

  Iterable<UserTag> filterTagsStartsWith(Iterable<String> terms) {
    return tags.where(
      (tag) => terms.every((term) => tag.name
          .toLowerCase()
          .split(' ')
          .any((word) => word.startsWith(term))),
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
      _loadUserTags(userId);
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
      _userTags = snapshot.data() ?? UserTags();

      // Ensure Firestore copy has at least as many classes as local clusters.
      for (var i = _userTags.classes.length;
          i < UserTag._tagClusters.length;
          ++i) {
        _userTags.classes.add(TagClass(name: UserTag._tagClusters[i].name));
      }

      _entryToTags.clear();
      _tagToEntries.clear();
      _tagToCluster.clear();

      for (var i = 0; i < _userTags.classes.length; ++i) {
        final cl = _userTags.classes[i];
        for (final tag in cl.tags) {
          _tagToCluster[tag.name] = i;

          for (final id in tag.gameIds) {
            var tags = _entryToTags[id];
            if (tags != null) {
              tags.add(UserTag(name: tag.name, clusterId: i));
            } else {
              _entryToTags[id] = [UserTag(name: tag.name, clusterId: i)];
            }

            var entries = _tagToEntries[tag.name];
            if (entries != null) {
              entries.add(id);
            } else {
              _tagToEntries[tag.name] = [id];
            }
          }
        }
      }

      notifyListeners();
    });
  }
}

class UserTag {
  String name;
  int _clusterId;

  UserTag({
    required this.name,
    clusterId = 0,
  }) : _clusterId = clusterId;

  MaterialColor get color => _tagClusters[_clusterId].color;

  static List<_UserTagCluster> _tagClusters = [
    _UserTagCluster(name: 'grey', color: Colors.blueGrey),
    _UserTagCluster(name: 'orange', color: Colors.orange),
    _UserTagCluster(name: 'green', color: Colors.green),
    _UserTagCluster(name: 'lime', color: Colors.lime),
  ];
}

class _UserTagCluster {
  String name;
  MaterialColor color;

  _UserTagCluster({
    required this.name,
    required this.color,
  });
}
