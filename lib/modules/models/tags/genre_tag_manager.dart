import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/user_tags.dart';

class GenreTagManager {
  GenreTagManager(this._userId, this._userTags);

  Iterable<Genre> byGameId(int gameId) => _gameIdToGenres[gameId] ?? [];

  UnmodifiableListView<Genre> get genres => UnmodifiableListView(
      _genreToGameIds.keys.toList()..sort((a, b) => a.name.compareTo(b.name)));

  UnmodifiableListView<Genre> get genresByPopulation {
    final list = _genreToGameIds.entries
        .map((e) => MapEntry(e.key, e.value.length))
        .toList()
      ..sort((a, b) => -a.value.compareTo(b.value));
    return UnmodifiableListView(list.map((e) => e.key));
  }

  Iterable<int> gameIds(Genre genre) => _genreToGameIds[genre] ?? [];

  Iterable<Genre> filter(Iterable<String> ngrams) {
    return genres.where(
      (genre) => ngrams.every((ngram) => genre.name
          .toLowerCase()
          .split(' ')
          .any((word) => word.startsWith(ngram))),
    );
  }

  Iterable<Genre> filterExact(Iterable<String> ngrams) {
    return genres.where(
      (tag) => ngrams.every((ngram) =>
          tag.name.toLowerCase().split(' ').any((word) => word == ngram)),
    );
  }

  void add(Genre genre, int gameId) async {
    _addTag(genre, gameId);

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userTags.toJson());
  }

  void remove(Genre genre, int gameId) async {
    _removeTag(genre, gameId);

    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('user_data')
        .doc('tags')
        .set(_userTags.toJson());
  }

  void _addTag(Genre genre, int gameId) {
    for (final value in _userTags.genres) {
      if (value.name == genre.name) {
        value.gameIds.add(gameId);
        return;
      }
    }

    // New Genre, add new Genre in UserTags.
    _userTags.genres.add(
      Genre(
        root: genre.root,
        name: genre.name,
        gameIds: [gameId],
      ),
    );
  }

  void _removeTag(Genre genre, int gameId) {
    for (final value in _userTags.genres) {
      if (value.name == genre.name) {
        value.gameIds.remove(gameId);
        return;
      }
    }
  }

  final String _userId;
  final UserTags _userTags;

  final Map<int, List<Genre>> _gameIdToGenres = {};
  final Map<Genre, List<int>> _genreToGameIds = {};

  void build() {
    _gameIdToGenres.clear();
    _genreToGameIds.clear();

    // Build Genre index.
    for (final genre in _userTags.genres) {
      for (final id in genre.gameIds) {
        final genreCopy = Genre(root: genre.root, name: genre.name);
        final genres = _gameIdToGenres[id];
        if (genres != null) {
          genres.add(genreCopy);
        } else {
          _gameIdToGenres[id] = [genreCopy];
        }

        final gameIds = _genreToGameIds[genreCopy];
        if (gameIds != null) {
          gameIds.add(id);
        } else {
          _genreToGameIds[genreCopy] = [id];
        }
      }
    }
  }
}
