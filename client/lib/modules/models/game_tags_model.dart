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
  String _userId = '';

  // System defined tags.
  Set<String> _stores = {};
  Set<String> _companies = {};
  Map<String, int> _collections = {};

  UserTagManager _tagsManager = UserTagManager();

  UnmodifiableListView<String> get stores => UnmodifiableListView(_stores);

  UnmodifiableListView<String> get companies =>
      UnmodifiableListView(_companies);

  UnmodifiableListView<String> get collections =>
      UnmodifiableListView(_collections.entries
          .where((entry) => entry.value > 1)
          .map((entry) => entry.key)
          .toList()
        ..sort());

  int getCollectionSize(String collection) => _collections[collection] ?? 0;

  UserTagManager get userTags => _tagsManager;

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
      _tagsManager = UserTagManager(_userId, snapshot.data() ?? UserTags())
        ..build();
      notifyListeners();
    });
  }
}

class UserTagManager {
  UserTagManager([this._userId = '', this._userTags = const UserTags()]);

  UserTag get(String name) =>
      UserTag(name: name, clusterId: _tagToCluster[name] ?? 0);

  Iterable<UserTag> byEntry(int gameId) => _entryToTags[gameId] ?? [];

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

  UnmodifiableListView<UserTag> tagByPopulationInCluster(String cluster) {
    final list = _tagToCluster.entries
        .map((e) => UserTag(name: e.key, clusterId: e.value))
        .where((tag) => tag.cluster == cluster)
        .map((tag) => MapEntry(tag, _tagToEntries[tag.name]?.length ?? 0))
        .toList()
      ..sort((a, b) => -a.value.compareTo(b.value));
    return UnmodifiableListView(list.map((e) => e.key));
  }

  Iterable<int> entriesByTag(String tag) => _tagToEntries[tag] ?? [];

  Iterable<UserTag> filter(Iterable<String> ngrams) {
    return tags.where(
      (tag) => ngrams.every((ngram) => tag.name
          .toLowerCase()
          .split(' ')
          .any((word) => word.startsWith(ngram))),
    );
  }

  Iterable<UserTag> filterExact(Iterable<String> ngrams) {
    return tags.where(
      (tag) => ngrams.every((ngram) =>
          tag.name.toLowerCase().split(' ').any((word) => word == ngram)),
    );
  }

  void add(UserTag tag, int gameId) async {
    _addTag(tag, gameId);

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userTags.toJson());
  }

  void remove(UserTag userTag, int gameId) async {
    _removeTag(userTag, gameId);

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userTags.toJson());
  }

  void moveCluster(UserTag userTag) async {
    _moveCluster(userTag);

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userTags.toJson());
  }

  void _addTag(UserTag userTag, int gameId) {
    final cluster = _userTags.classes[userTag._clusterId];

    for (final tag in cluster.tags) {
      if (tag.name == userTag.name) {
        tag.gameIds.add(gameId);
        return;
      }
    }

    // New Tag, create new Tag in the class.
    cluster.tags.add(
      Tag(
        name: userTag.name,
        gameIds: [gameId],
      ),
    );
  }

  void _removeTag(UserTag userTag, int gameId) {
    for (final cluster in _userTags.classes) {
      int index = 0;
      for (final tag in cluster.tags) {
        if (tag.name == userTag.name) {
          tag.gameIds.remove(gameId);

          if (tag.gameIds.isEmpty) {
            cluster.tags.removeAt(index);
          }
          break;
        }
        ++index;
      }
    }
  }

  void _moveCluster(UserTag userTag) {
    final cluster = _userTags.classes[userTag._clusterId];
    final newCluster = (userTag._clusterId + 1) % UserTag._tagClusters.length;

    for (var i = 0; i < cluster.tags.length; ++i) {
      final tag = cluster.tags[i];
      if (tag.name == userTag.name) {
        _userTags.classes[newCluster].tags.add(tag);
        cluster.tags.removeAt(i);
        break;
      }
    }
  }

  String _userId = '';
  UserTags _userTags = UserTags();
  Map<int, List<UserTag>> _entryToTags = {};
  Map<String, List<int>> _tagToEntries = {};
  Map<String, int> _tagToCluster = {};

  void build() {
    // Ensure Firestore copy has at least as many clusters as the local clusters.
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
  String get cluster => _tagClusters[_clusterId].name;

  static List<_UserTagCluster> _tagClusters = [
    _UserTagCluster(name: 'genre', color: Colors.blueGrey),
    _UserTagCluster(name: 'style', color: Colors.orange),
    _UserTagCluster(name: 'theme', color: Colors.green),
    _UserTagCluster(name: 'other', color: Colors.lime),
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
