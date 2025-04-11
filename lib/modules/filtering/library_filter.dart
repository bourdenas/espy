import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/genres_mapping.dart';

class LibraryFilter {
  LibraryFilter({
    this.store,
    this.genreGroup,
    this.genre,
    this.keyword,
    this.score,
  });

  String? store;
  String? genreGroup;
  String? genre;
  String? keyword;
  String? score;

  bool equals(LibraryFilter other) {
    return store == other.store &&
        genreGroup == other.genreGroup &&
        genre == other.genre &&
        keyword == other.keyword &&
        score == other.score;
  }

  bool get isEmpty => !isNotEmpty;

  bool get isNotEmpty =>
      store != null ||
      genreGroup != null ||
      genre != null ||
      keyword != null ||
      score != null;

  LibraryFilter add(LibraryFilter other) {
    return LibraryFilter(
      store: other.store ?? store,
      genreGroup: other.genreGroup ?? genreGroup,
      genre: other.genre ?? genre,
      keyword: other.keyword ?? keyword,
      score: other.score ?? score,
    );
  }

  LibraryFilter subtract(LibraryFilter other) {
    return LibraryFilter(
      store: other.store == null ? store : null,
      genreGroup: other.genreGroup == null ? genreGroup : null,
      genre: other.genre == null ? genre : null,
      keyword: other.keyword == null ? keyword : null,
      score: other.score == null ? score : null,
    );
  }

  bool pass(GameDigest digest) {
    return true &&
        (genreGroup == null ||
            digest.espyGenres
                .any((e) => Genres.groupOfGenre(e) == genreGroup) ||
            (digest.espyGenres.isEmpty && genreGroup == 'Unknown')) &&
        (genre == null ||
            digest.espyGenres.any((e) => e == genre) ||
            (digest.espyGenres.isEmpty && genre == 'Unknown')) &&
        (keyword == null || digest.keywords.any((e) => e == keyword)) &&
        (score == null || digest.scores.title == score);
  }

  bool passLibraryEntry(LibraryEntry entry) {
    return pass(entry.digest) &&
        (store == null || entry.storeEntries.any((e) => e.storefront == store));
  }

  Map<String, String> params() {
    return {
      if (store != null) 'str': store!,
      if (genreGroup != null) 'ggr': genreGroup!,
      if (genre != null) 'gnr': genre!,
      if (keyword != null) 'kw': keyword!,
    };
  }

  factory LibraryFilter.fromParams(Map<String, String> params) {
    var filter = LibraryFilter();

    params.forEach((key, value) {
      if (key == 'str') {
        filter.store = value;
      } else if (key == 'ggr') {
        filter.genreGroup = value;
      } else if (key == 'gnr') {
        filter.genre = value;
      } else if (key == 'kw') {
        filter.keyword = value;
      }
    });
    return filter;
  }
}
