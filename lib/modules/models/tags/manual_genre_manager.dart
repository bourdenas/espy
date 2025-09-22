import 'package:espy/modules/api/auth_user_api.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_annotations.dart';

class ManualGenreManager {
  ManualGenreManager(this._userTags, this._getEntryById);

  Iterable<Genre> byGameId(int gameId) => _gameIdToGenres[gameId] ?? [];

  Iterable<Genre> get all => _genres;

  Iterable<int> gameIds(String genre) => _genreToGameIds[genre] ?? [];
  Iterable<LibraryEntry> games(String genre) =>
      gameIds(genre).map((id) => _getEntryById(id)).whereType<LibraryEntry>();

  Iterable<Genre> filter(Iterable<String> ngrams) {
    return all.where((e) => e.label.isNotEmpty).where(
          (genre) => ngrams.every((ngram) => genre.label
              .toLowerCase()
              .split(' ')
              .any((word) => word.startsWith(ngram))),
        );
  }

  Iterable<Genre> filterExact(Iterable<String> ngrams) {
    return all.where((e) => e.label.isNotEmpty).where(
          (tag) => ngrams.every((ngram) =>
              tag.label.toLowerCase().split(' ').any((word) => word == ngram)),
        );
  }

  void add(int gameId, String genre) async {
    await AuthUserApi.updateGenre(gameId, genre);
  }

  void remove(int gameId) async {
    await AuthUserApi.updateGenre(gameId, null);
  }

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
      final genreCopy = Genre(label: genre.label);
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
