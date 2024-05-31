import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_annotations.dart';

class ManualGenreManager {
  ManualGenreManager(this._userId, this._userTags, this._getEntryById);

  Iterable<Genre> byGameId(int gameId) => _gameIdToGenres[gameId] ?? [];

  Iterable<Genre> get all => _genres;

  Iterable<int> gameIds(String genre) => _genreToGameIds[genre] ?? [];
  Iterable<LibraryEntry> games(String genre) =>
      gameIds(genre).map((id) => _getEntryById(id)).whereType<LibraryEntry>();

  Iterable<Genre> filter(Iterable<String> ngrams) {
    return all.where((e) => e.name.isNotEmpty).where(
          (genre) => ngrams.every((ngram) => genre.name
              .toLowerCase()
              .split(' ')
              .any((word) => word.startsWith(ngram))),
        );
  }

  Iterable<Genre> filterExact(Iterable<String> ngrams) {
    return all.where((e) => e.name.isNotEmpty).where(
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
  final UserAnnotations _userTags;
  final LibraryEntry? Function(int) _getEntryById;

  final Map<int, List<Genre>> _gameIdToGenres = {};
  final Map<String, List<int>> _genreToGameIds = {};
  List<Genre> _genres = [];

  void build() {
    final genreHistogram = <(Genre, int)>[];

    // Build Genre index.
    for (final genre in _userTags.genres) {
      if (genre.gameIds.isEmpty) {
        continue;
      }
      final genreCopy = Genre(name: genre.name);
      genreHistogram.add((genreCopy, genre.gameIds.length));

      for (final id in genre.gameIds) {
        final genres = _gameIdToGenres[id];
        if (genres != null) {
          genres.add(genreCopy);
        } else {
          _gameIdToGenres[id] = [genreCopy];
        }

        final gameIds = _genreToGameIds[genreCopy.encode()];
        if (gameIds != null) {
          gameIds.add(id);
        } else {
          _genreToGameIds[genreCopy.encode()] = [id];
        }
      }
    }

    genreHistogram.sort((a, b) => b.$2 - a.$2);
    _genres = genreHistogram.map((e) => e.$1).toList();
  }
}
