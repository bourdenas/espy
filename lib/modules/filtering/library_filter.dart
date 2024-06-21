import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_view.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/genres_mapping.dart';

class LibraryFilter {
  LibraryFilter({
    this.store,
    this.developer,
    this.publisher,
    this.collection,
    this.franchise,
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
        genreGroup == other.genreGroup &&
        genre == other.genre &&
        keyword == other.keyword &&
        manualGenre == other.manualGenre &&
        userTag == other.userTag;
  }

  bool get isNotEmpty =>
      store != null ||
      developer != null ||
      publisher != null ||
      collection != null ||
      franchise != null ||
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
      genreGroup: other.genreGroup == null ? genreGroup : null,
      genre: other.genre == null ? genre : null,
      keyword: other.keyword == null ? keyword : null,
      manualGenre: other.manualGenre == null ? manualGenre : null,
      userTag: other.userTag == null ? userTag : null,
    );
  }

  LibraryView apply(
    GameTagsModel tagsModel,
    LibraryEntry? Function(int) entriesIndex,
  ) {
    List<Set<int>> gameIdSets = [];

    if (store != null) {
      gameIdSets.add(Set.from(tagsModel.stores.gameIds(store!)));
    }
    if (developer != null) {
      gameIdSets.add(Set.from(tagsModel.developers.gameIds(developer!)));
    }
    if (publisher != null) {
      gameIdSets.add(Set.from(tagsModel.publishers.gameIds(publisher!)));
    }
    if (collection != null) {
      gameIdSets.add(Set.from(tagsModel.collections.gameIds(collection!)));
    }
    if (franchise != null) {
      gameIdSets.add(Set.from(tagsModel.franchises.gameIds(franchise!)));
    }
    if (genreGroup != null) {
      final groupSet = <int>{};
      for (final genre in Genres.genresInGroup(genreGroup!) ?? []) {
        groupSet.addAll(tagsModel.genres.gameIds(genre));
      }
      gameIdSets.add(groupSet);
    }
    if (genre != null) {
      gameIdSets.add(Set.from(tagsModel.genres.gameIds(genre!)));
    }
    if (manualGenre != null) {
      gameIdSets.add(Set.from(tagsModel.manualGenres.gameIds(manualGenre!)));
    }
    if (userTag != null) {
      gameIdSets.add(Set.from(tagsModel.userTags.gameIdsByTag(userTag!)));
    }

    final gameIds =
        gameIdSets.reduce((value, element) => value.intersection(element));

    final filteredEntries = gameIds
        .map((id) => entriesIndex(id))
        .where((e) => e != null)
        .map((e) => e!);

    return LibraryView(filteredEntries.toList());
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
