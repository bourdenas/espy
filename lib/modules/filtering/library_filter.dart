import 'dart:collection';

import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_view.dart';
import 'package:espy/modules/models/game_tags_model.dart';

class LibraryFilter {
  LibraryFilter({
    this.stores = const {},
    this.developers = const {},
    this.publishers = const {},
    this.collections = const {},
    this.franchises = const {},
    this.genres = const {},
    this.genreTags = const {},
    this.keywords = const {},
    this.tags = const {},
  });

  Set<String> stores;
  Set<String> developers;
  Set<String> publishers;
  Set<String> collections;
  Set<String> franchises;
  Set<String> genres;
  Set<String> genreTags;
  Set<String> keywords;
  Set<String> tags;

  LibraryFilter add(LibraryFilter other) {
    return LibraryFilter(
      stores: stores.union(other.stores),
      developers: developers.union(other.developers),
      publishers: publishers.union(other.publishers),
      collections: collections.union(other.collections),
      franchises: franchises.union(other.franchises),
      genres: genres.union(other.genres),
      genreTags: genreTags.union(other.genreTags),
      keywords: keywords.union(other.keywords),
      tags: tags.union(other.tags),
    );
  }

  LibraryFilter remove(LibraryFilter other) {
    return LibraryFilter(
      stores: stores.difference(other.stores),
      developers: developers.difference(other.developers),
      publishers: publishers.difference(other.publishers),
      collections: collections.difference(other.collections),
      franchises: franchises.difference(other.franchises),
      genres: genres.difference(other.genres),
      genreTags: genreTags.difference(other.genreTags),
      keywords: keywords.difference(other.keywords),
      tags: tags.difference(other.tags),
    );
  }

  bool contains(LibraryFilter other) {
    return other.stores.difference(stores).isEmpty &&
        other.developers.difference(developers).isEmpty &&
        other.publishers.difference(publishers).isEmpty &&
        other.collections.difference(collections).isEmpty &&
        other.franchises.difference(franchises).isEmpty &&
        other.genres.difference(genres).isEmpty &&
        other.genreTags.difference(genreTags).isEmpty &&
        other.keywords.difference(keywords).isEmpty &&
        other.tags.difference(tags).isEmpty;
  }

  bool get isNotEmpty =>
      stores.isNotEmpty ||
      developers.isNotEmpty ||
      publishers.isNotEmpty ||
      collections.isNotEmpty ||
      franchises.isNotEmpty ||
      genres.isNotEmpty ||
      genreTags.isNotEmpty ||
      keywords.isNotEmpty ||
      tags.isNotEmpty;

  LibraryView apply(
    HashMap<int, LibraryEntry> entriesById,
    GameTagsModel tagsModel,
  ) {
    List<Set<int>> gameIdSets = [];

    for (final store in stores) {
      gameIdSets.add(Set.from(tagsModel.stores.gameIds(store)));
    }
    for (final company in developers) {
      gameIdSets.add(Set.from(tagsModel.developers.gameIds(company)));
    }
    for (final company in publishers) {
      gameIdSets.add(Set.from(tagsModel.publishers.gameIds(company)));
    }
    for (final collection in collections) {
      gameIdSets.add(Set.from(tagsModel.collections.gameIds(collection)));
    }
    for (final franchise in franchises) {
      gameIdSets.add(Set.from(tagsModel.franchises.gameIds(franchise)));
    }
    for (final genre in genres) {
      gameIdSets.add(Set.from(tagsModel.genres.gameIds(genre)));
    }
    for (final genreTag in genreTags) {
      gameIdSets.add(Set.from(tagsModel.genreTags.gameIds(genreTag)));
    }
    for (final tag in tags) {
      gameIdSets.add(Set.from(tagsModel.userTags.gameIds(tag)));
    }

    final gameIds =
        gameIdSets.reduce((value, element) => value.intersection(element));

    final filteredEntries = gameIds
        .map((id) => entriesById[id])
        .where((e) => e != null)
        .map((e) => e!);

    return LibraryView(filteredEntries.toList());
  }

  Map<String, String> params() {
    return {
      if (developers.isNotEmpty) 'dev': developers.map((c) => c).join(':'),
      if (publishers.isNotEmpty) 'pub': publishers.map((c) => c).join(':'),
      if (collections.isNotEmpty) 'col': collections.map((c) => c).join(':'),
      if (franchises.isNotEmpty) 'frn': franchises.map((c) => c).join(':'),
      if (genres.isNotEmpty) 'gnr': genres.map((c) => c).join(':'),
      if (genreTags.isNotEmpty) 'gnt': genreTags.map((c) => c).join(':'),
      if (keywords.isNotEmpty) 'kw': keywords.map((c) => c).join(':'),
      if (tags.isNotEmpty) 'tag': tags.map((t) => t).join(':'),
      if (stores.isNotEmpty) 'str': stores.map((s) => s).join(':'),
    };
  }

  factory LibraryFilter.fromParams(Map<String, String> params) {
    var filter = LibraryFilter();

    params.forEach((key, value) {
      if (key == 'dev') {
        filter.developers = value.split(':').toSet();
      } else if (key == 'pub') {
        filter.publishers = value.split(':').toSet();
      } else if (key == 'col') {
        filter.collections = value.split(':').toSet();
      } else if (key == 'frn') {
        filter.franchises = value.split(':').toSet();
      } else if (key == 'gnr') {
        filter.genres = value.split(':').toSet();
      } else if (key == 'gnt') {
        filter.genreTags = value.split(':').toSet();
      } else if (key == 'kw') {
        filter.keywords = value.split(':').toSet();
      } else if (key == 'tag') {
        filter.tags = value.split(':').toSet();
      } else if (key == 'str') {
        filter.stores = value.split(':').toSet();
      }
    });
    return filter;
  }
}
