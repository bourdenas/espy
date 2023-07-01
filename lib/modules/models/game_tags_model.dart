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

  LabelManager _storesManager = LabelManager([]);
  LabelManager _developersManager = LabelManager([]);
  LabelManager _publishersManager = LabelManager([]);
  LabelManager _collectionsManager = LabelManager([]);
  LabelManager _franchisesManager = LabelManager([]);
  LabelManager _genresManager = LabelManager([]);
  LabelManager _keywordsManager = LabelManager([]);
  UserTagManager _userTagsManager = UserTagManager('', UserTags());

  LabelManager get stores => _storesManager;
  LabelManager get developers => _developersManager;
  LabelManager get publishers => _publishersManager;
  LabelManager get collections => _collectionsManager;
  LabelManager get franchises => _franchisesManager;
  LabelManager get genres => _genresManager;
  LabelManager get keywords => _keywordsManager;
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
      _userTagsManager = UserTagManager(_userId, snapshot.data() ?? UserTags())
        ..build();
      notifyListeners();
    });
  }
}

class LabelManager {
  LabelManager(Iterable<LibraryEntry> entries,
      [Iterable<String> Function(LibraryEntry)? labelExtractor]) {
    if (labelExtractor == null) return;

    for (final entry in entries) {
      for (final label in labelExtractor(entry)) {
        (_labelToGameIds[label] ??= []).add(entry.id);
      }
    }
  }

  UnmodifiableListView<String> get all =>
      UnmodifiableListView(_labelToGameIds.keys.toList()..sort());

  UnmodifiableListView<String> get nonSingleton =>
      UnmodifiableListView(_labelToGameIds.entries
          .where((entry) => entry.value.length > 1)
          .map((entry) => entry.key)
          .toList()
        ..sort());

  Iterable<int> gameIds(String label) => _labelToGameIds[label] ?? [];

  int size(String label) => _labelToGameIds[label]?.length ?? 0;

  Iterable<String> filter(Iterable<String> ngrams) {
    return nonSingleton.where((label) => ngrams.every((ngram) =>
        label.toLowerCase().split(' ').any((word) => word.startsWith(ngram))));
  }

  Iterable<String> filterExact(Iterable<String> ngrams) {
    return nonSingleton.where((label) => ngrams.every((ngram) =>
        label.toLowerCase().split(' ').any((word) => word == ngram)));
  }

  final Map<String, List<int>> _labelToGameIds = {};
}

class UserTagManager {
  UserTagManager(this._userId, this._userTags);

  UserTag get(String name) =>
      UserTag(name: name, clusterId: _tagToCluster[name] ?? 0);

  Iterable<UserTag> byGameId(int gameId) => _gameIdToTags[gameId] ?? [];

  UnmodifiableListView<UserTag> get tags =>
      UnmodifiableListView(_tagToCluster.entries
          .map((entry) => UserTag(name: entry.key, clusterId: entry.value))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  UnmodifiableListView<String> get tagsByPopulation {
    final list = _tagToGameIds.entries
        .map((e) => MapEntry(e.key, e.value.length))
        .toList()
      ..sort((a, b) => -a.value.compareTo(b.value));
    return UnmodifiableListView(list.map((e) => e.key));
  }

  UnmodifiableListView<UserTag> tagByPopulationInCluster(String cluster) {
    final list = _tagToCluster.entries
        .map((e) => UserTag(name: e.key, clusterId: e.value))
        .where((tag) => tag.cluster == cluster)
        .map((tag) => MapEntry(tag, _tagToGameIds[tag.name]?.length ?? 0))
        .toList()
      ..sort((a, b) => -a.value.compareTo(b.value));
    return UnmodifiableListView(list.map((e) => e.key));
  }

  Iterable<int> gameIds(String tag) => _tagToGameIds[tag] ?? [];

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

  final String _userId;
  final UserTags _userTags;
  final Map<int, List<UserTag>> _gameIdToTags = {};
  final Map<String, List<int>> _tagToGameIds = {};
  final Map<String, int> _tagToCluster = {};

  void build() {
    // Ensure Firestore copy has at least as many clusters as the local clusters.
    for (var i = _userTags.classes.length;
        i < UserTag._tagClusters.length;
        ++i) {
      _userTags.classes.add(TagClass(name: UserTag._tagClusters[i].name));
    }

    _gameIdToTags.clear();
    _tagToGameIds.clear();
    _tagToCluster.clear();

    for (var i = 0; i < _userTags.classes.length; ++i) {
      final cl = _userTags.classes[i];
      for (final tag in cl.tags) {
        _tagToCluster[tag.name] = i;

        for (final id in tag.gameIds) {
          var tags = _gameIdToTags[id];
          if (tags != null) {
            tags.add(UserTag(name: tag.name, clusterId: i));
          } else {
            _gameIdToTags[id] = [UserTag(name: tag.name, clusterId: i)];
          }

          var entries = _tagToGameIds[tag.name];
          if (entries != null) {
            entries.add(id);
          } else {
            _tagToGameIds[tag.name] = [id];
          }
        }
      }
    }
  }
}

class UserTag {
  String name;
  final int _clusterId;

  UserTag({
    required this.name,
    clusterId = 0,
  }) : _clusterId = clusterId;

  MaterialColor get color => _tagClusters[_clusterId].color;
  String get cluster => _tagClusters[_clusterId].name;

  static final List<_UserTagCluster> _tagClusters = [
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
