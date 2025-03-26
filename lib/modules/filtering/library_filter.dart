import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/genres_mapping.dart';

class LibraryFilter {
  LibraryFilter({
    this.store,
    this.developer,
    this.publisher,
    this.collection,
    this.franchise,
    this.score,
    this.genreGroup,
    this.genre,
    this.keyword,
    this.manualGenre,
    this.userTag,
  });

  String? store;
  String? developer;
  String? publisher;
  String? collection;
  String? franchise;
  String? score;
  String? genreGroup;
  String? genre;
  String? keyword;
  String? manualGenre;
  String? userTag;

  bool equals(LibraryFilter other) {
    return store == other.store &&
        developer == other.developer &&
        publisher == other.publisher &&
        collection == other.collection &&
        franchise == other.franchise &&
        score == other.score &&
        genreGroup == other.genreGroup &&
        genre == other.genre &&
        keyword == other.keyword &&
        manualGenre == other.manualGenre &&
        userTag == other.userTag;
  }

  bool get isEmpty => !isNotEmpty;

  bool get isNotEmpty =>
      store != null ||
      developer != null ||
      publisher != null ||
      collection != null ||
      franchise != null ||
      score != null ||
      genreGroup != null ||
      genre != null ||
      keyword != null ||
      manualGenre != null ||
      userTag != null;

  LibraryFilter add(LibraryFilter other) {
    return LibraryFilter(
      store: other.store ?? store,
      developer: other.developer ?? developer,
      publisher: other.publisher ?? publisher,
      collection: other.collection ?? collection,
      franchise: other.franchise ?? franchise,
      score: other.score ?? score,
      genreGroup: other.genreGroup ?? genreGroup,
      genre: other.genre ?? genre,
      keyword: other.keyword ?? keyword,
      manualGenre: other.manualGenre ?? manualGenre,
      userTag: other.userTag ?? userTag,
    );
  }

  LibraryFilter subtract(LibraryFilter other) {
    return LibraryFilter(
      store: other.store == null ? store : null,
      developer: other.developer == null ? developer : null,
      publisher: other.publisher == null ? publisher : null,
      collection: other.collection == null ? collection : null,
      franchise: other.franchise == null ? franchise : null,
      score: other.score == null ? score : null,
      genreGroup: other.genreGroup == null ? genreGroup : null,
      genre: other.genre == null ? genre : null,
      keyword: other.keyword == null ? keyword : null,
      manualGenre: other.manualGenre == null ? manualGenre : null,
      userTag: other.userTag == null ? userTag : null,
    );
  }

  bool pass(LibraryEntry entry) {
    return (store == null ||
            entry.storeEntries.any((e) => e.storefront == store)) &&
        (developer == null ||
            entry.digest.developers.any((e) => e == developer)) &&
        (publisher == null ||
            entry.digest.publishers.any((e) => e == publisher)) &&
        (collection == null ||
            entry.digest.collections.any((e) => e == collection)) &&
        (franchise == null ||
            entry.digest.franchises.any((e) => e == franchise)) &&
        (score == null || entry.scores.title == score) &&
        (genreGroup == null ||
            entry.digest.espyGenres
                .any((e) => Genres.groupOfGenre(e) == genreGroup) ||
            (entry.digest.espyGenres.isEmpty && genreGroup == 'Unknown')) &&
        (genre == null ||
            entry.digest.espyGenres.any((e) => e == genre) ||
            (entry.digest.espyGenres.isEmpty && genre == 'Unknown')) &&
        (keyword == null || entry.digest.keywords.any((e) => e == keyword));
  }

  Map<String, String> params() {
    return {
      if (store != null) 'str': store!,
      if (developer != null) 'dev': developer!,
      if (publisher != null) 'pub': publisher!,
      if (collection != null) 'col': collection!,
      if (franchise != null) 'frn': franchise!,
      if (genreGroup != null) 'ggr': genreGroup!,
      if (genre != null) 'gnr': genre!,
      if (keyword != null) 'kw': keyword!,
      if (manualGenre != null) 'gnt': manualGenre!,
      if (userTag != null) 'tag': userTag!,
    };
  }

  factory LibraryFilter.fromParams(Map<String, String> params) {
    var filter = LibraryFilter();

    params.forEach((key, value) {
      if (key == 'str') {
        filter.store = value;
      } else if (key == 'dev') {
        filter.developer = value;
      } else if (key == 'pub') {
        filter.publisher = value;
      } else if (key == 'col') {
        filter.collection = value;
      } else if (key == 'frn') {
        filter.franchise = value;
      } else if (key == 'ggr') {
        filter.genreGroup = value;
      } else if (key == 'gnr') {
        filter.genre = value;
      } else if (key == 'kw') {
        filter.keyword = value;
      } else if (key == 'gnt') {
        filter.manualGenre = value;
      } else if (key == 'tag') {
        filter.userTag = value;
      }
    });
    return filter;
  }
}
