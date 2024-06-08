import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_annotations.dart';

class UserTagManager {
  UserTagManager(this._userId, this._userAnnotations, this._getEntryById);

  Iterable<String> get userTags => _tagToGameIds.keys;

  UnmodifiableListView<String> get tagsByPopulation {
    final list = _tagToGameIds.entries
        .map((e) => MapEntry(e.key, e.value.length))
        .toList()
      ..sort((a, b) => -a.value.compareTo(b.value));
    return UnmodifiableListView(list.map((e) => e.key));
  }

  Iterable<String> tagsByGameId(int gameId) => _gameIdToTags[gameId] ?? [];
  Iterable<int> gameIdsByTag(String tag) => _tagToGameIds[tag] ?? [];
  Iterable<LibraryEntry> games(String tag) => gameIdsByTag(tag)
      .map((id) => _getEntryById(id))
      .whereType<LibraryEntry>();

  Iterable<String> filter(Iterable<String> ngrams) {
    return userTags.where(
      (userTag) => ngrams.every((ngram) => userTag
          .toLowerCase()
          .split(' ')
          .any((word) => word.startsWith(ngram))),
    );
  }

  Iterable<String> filterExact(Iterable<String> ngrams) {
    return userTags.where(
      (userTag) => ngrams.every((ngram) =>
          userTag.toLowerCase().split(' ').any((word) => word == ngram)),
    );
  }

  void add(String userTag, int gameId) async {
    _addTag(userTag, gameId);

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userAnnotations.toJson());
  }

  void remove(String userTag, int gameId) async {
    _removeTag(userTag, gameId);

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userAnnotations.toJson());
  }

  void _addTag(String userTag, int gameId) {
    for (final tag in _userAnnotations.userTags) {
      if (tag.name == userTag) {
        tag.gameIds.add(gameId);
        return;
      }
    }

    // New Tag, create new Tag in the class.
    _userAnnotations.userTags.add(
      UserTag(userTag, gameIds: [gameId]),
    );
  }

  void _removeTag(String userTag, int gameId) {
    var index = 0;
    for (final tag in _userAnnotations.userTags) {
      if (tag.name == userTag) {
        tag.gameIds.remove(gameId);

        if (tag.gameIds.isEmpty) {
          _userAnnotations.userTags.removeAt(index);
        }
        break;
      }
      ++index;
    }
  }

  final String _userId;
  final UserAnnotations _userAnnotations;
  final LibraryEntry? Function(int) _getEntryById;

  final Map<int, List<String>> _gameIdToTags = {};
  final Map<String, List<int>> _tagToGameIds = {};

  void build() {
    _gameIdToTags.clear();
    _tagToGameIds.clear();

    // Build UserTag index.
    for (final userTag in _userAnnotations.userTags) {
      for (final id in userTag.gameIds) {
        (_gameIdToTags[id] ??= []).add(userTag.name);
        (_tagToGameIds[userTag.name] ??= []).add(id);
      }
    }
  }
}
