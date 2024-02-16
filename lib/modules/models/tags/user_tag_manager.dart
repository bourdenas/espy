import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_tags.dart';
import 'package:flutter/material.dart' show Colors, MaterialColor;

class UserTagManager {
  UserTagManager(this._userId, this._userTags, this._getEntryById);

  CustomUserTag get(String name) =>
      CustomUserTag(name: name, clusterId: _tagToCluster[name] ?? 0);

  Iterable<CustomUserTag> byGameId(int gameId) => _gameIdToTags[gameId] ?? [];

  UnmodifiableListView<CustomUserTag> get tags =>
      UnmodifiableListView(_tagToCluster.entries
          .map(
              (entry) => CustomUserTag(name: entry.key, clusterId: entry.value))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  UnmodifiableListView<String> get tagsByPopulation {
    final list = _tagToGameIds.entries
        .map((e) => MapEntry(e.key, e.value.length))
        .toList()
      ..sort((a, b) => -a.value.compareTo(b.value));
    return UnmodifiableListView(list.map((e) => e.key));
  }

  UnmodifiableListView<CustomUserTag> tagByPopulationInCluster(String cluster) {
    final list = _tagToCluster.entries
        .map((e) => CustomUserTag(name: e.key, clusterId: e.value))
        .where((tag) => tag.cluster == cluster)
        .map((tag) => MapEntry(tag, _tagToGameIds[tag.name]?.length ?? 0))
        .toList()
      ..sort((a, b) => -a.value.compareTo(b.value));
    return UnmodifiableListView(list.map((e) => e.key));
  }

  Iterable<int> gameIds(String tag) => _tagToGameIds[tag] ?? [];
  Iterable<LibraryEntry> games(String tag) =>
      gameIds(tag).map((id) => _getEntryById(id)).whereType<LibraryEntry>();

  Iterable<CustomUserTag> filter(Iterable<String> ngrams) {
    return tags.where(
      (tag) => ngrams.every((ngram) => tag.name
          .toLowerCase()
          .split(' ')
          .any((word) => word.startsWith(ngram))),
    );
  }

  Iterable<CustomUserTag> filterExact(Iterable<String> ngrams) {
    return tags.where(
      (tag) => ngrams.every((ngram) =>
          tag.name.toLowerCase().split(' ').any((word) => word == ngram)),
    );
  }

  void add(CustomUserTag userTag, int gameId) async {
    _addTag(userTag, gameId);

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userTags.toJson());
  }

  void remove(CustomUserTag userTag, int gameId) async {
    _removeTag(userTag, gameId);

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userTags.toJson());
  }

  void moveCluster(CustomUserTag userTag) async {
    _moveCluster(userTag);

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userTags.toJson());
  }

  void _addTag(CustomUserTag userTag, int gameId) {
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

  void _removeTag(CustomUserTag userTag, int gameId) {
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

  void _moveCluster(CustomUserTag userTag) {
    final cluster = _userTags.classes[userTag._clusterId];
    final newCluster =
        (userTag._clusterId + 1) % CustomUserTag._tagClusters.length;

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
  final LibraryEntry? Function(int) _getEntryById;

  final Map<int, List<CustomUserTag>> _gameIdToTags = {};
  final Map<String, List<int>> _tagToGameIds = {};
  final Map<String, int> _tagToCluster = {};

  void build() {
    // Ensure Firestore copy has at least as many clusters as the local clusters.
    for (var i = _userTags.classes.length;
        i < CustomUserTag._tagClusters.length;
        ++i) {
      _userTags.classes.add(TagClass(name: CustomUserTag._tagClusters[i].name));
    }

    _gameIdToTags.clear();
    _tagToGameIds.clear();
    _tagToCluster.clear();

    // Build UserTag index.
    for (var i = 0; i < _userTags.classes.length; ++i) {
      final cl = _userTags.classes[i];
      for (final tag in cl.tags) {
        _tagToCluster[tag.name] = i;

        for (final id in tag.gameIds) {
          var tags = _gameIdToTags[id];
          if (tags != null) {
            tags.add(CustomUserTag(name: tag.name, clusterId: i));
          } else {
            _gameIdToTags[id] = [CustomUserTag(name: tag.name, clusterId: i)];
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

class CustomUserTag {
  String name;
  final int _clusterId;

  CustomUserTag({
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
