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
    this.genreGroups = const {},
    this.genres = const {},
    this.keywords = const {},
    this.manualGenres = const {},
    this.userTags = const {},
  });

  Set<String> stores;
  Set<String> developers;
  Set<String> publishers;
  Set<String> collections;
  Set<String> franchises;
  Set<String> genreGroups;
  Set<String> genres;
  Set<String> keywords;
  Set<String> manualGenres;
  Set<String> userTags;

  LibraryFilter add(LibraryFilter other) {
    return LibraryFilter(
      stores: stores.union(other.stores),
      developers: developers.union(other.developers),
      publishers: publishers.union(other.publishers),
      collections: collections.union(other.collections),
      franchises: franchises.union(other.franchises),
      genreGroups: genreGroups.union(other.genreGroups),
      genres: genres.union(other.genres),
      keywords: keywords.union(other.keywords),
      manualGenres: manualGenres.union(other.manualGenres),
      userTags: userTags.union(other.userTags),
    );
  }

  LibraryFilter remove(LibraryFilter other) {
    return LibraryFilter(
      stores: stores.difference(other.stores),
      developers: developers.difference(other.developers),
      publishers: publishers.difference(other.publishers),
      collections: collections.difference(other.collections),
      franchises: franchises.difference(other.franchises),
      genreGroups: genreGroups.difference(other.genreGroups),
      genres: genres.difference(other.genres),
      keywords: keywords.difference(other.keywords),
      manualGenres: manualGenres.difference(other.manualGenres),
      userTags: userTags.difference(other.userTags),
    );
  }

  bool contains(LibraryFilter other) {
    return other.stores.difference(stores).isEmpty &&
        other.developers.difference(developers).isEmpty &&
        other.publishers.difference(publishers).isEmpty &&
        other.collections.difference(collections).isEmpty &&
        other.franchises.difference(franchises).isEmpty &&
        other.genreGroups.difference(genreGroups).isEmpty &&
        other.genres.difference(genres).isEmpty &&
        other.keywords.difference(keywords).isEmpty &&
        other.manualGenres.difference(manualGenres).isEmpty &&
        other.userTags.difference(userTags).isEmpty;
  }

  bool equals(LibraryFilter other) {
    return contains(other) && other.contains(this);
  }

  bool get isNotEmpty =>
      stores.isNotEmpty ||
      developers.isNotEmpty ||
      publishers.isNotEmpty ||
      collections.isNotEmpty ||
      franchises.isNotEmpty ||
      genreGroups.isNotEmpty ||
      genres.isNotEmpty ||
      keywords.isNotEmpty ||
      manualGenres.isNotEmpty ||
      userTags.isNotEmpty;

  LibraryView apply(
    GameTagsModel tagsModel,
    LibraryEntry? Function(int) entriesIndex,
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
    for (final genreGroup in genreGroups) {
      final groupSet = <int>{};
      for (final genre in GameTagsModel.espyGenreTags(genreGroup) ?? []) {
        groupSet.addAll(tagsModel.genres.gameIds(genre));
      }
      gameIdSets.add(groupSet);
    }
    for (final genre in genres) {
      gameIdSets.add(Set.from(tagsModel.genres.gameIds(genre)));
    }
    for (final genreTag in manualGenres) {
      gameIdSets.add(Set.from(tagsModel.manualGenres.gameIds(genreTag)));
    }
    for (final tag in userTags) {
      gameIdSets.add(Set.from(tagsModel.userTags.gameIdsByTag(tag)));
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
      if (stores.isNotEmpty) 'str': stores.map((s) => s).join(':'),
      if (developers.isNotEmpty) 'dev': developers.map((c) => c).join(':'),
      if (publishers.isNotEmpty) 'pub': publishers.map((c) => c).join(':'),
      if (collections.isNotEmpty) 'col': collections.map((c) => c).join(':'),
      if (franchises.isNotEmpty) 'frn': franchises.map((c) => c).join(':'),
      if (genreGroups.isNotEmpty) 'ggr': genreGroups.map((c) => c).join(':'),
      if (genres.isNotEmpty) 'gnr': genres.map((c) => c).join(':'),
      if (keywords.isNotEmpty) 'kw': keywords.map((c) => c).join(':'),
      if (manualGenres.isNotEmpty) 'gnt': manualGenres.map((c) => c).join(':'),
      if (userTags.isNotEmpty) 'tag': userTags.map((t) => t).join(':'),
    };
  }

  factory LibraryFilter.fromParams(Map<String, String> params) {
    var filter = LibraryFilter();

    params.forEach((key, value) {
      if (key == 'str') {
        filter.stores = value.split(':').toSet();
      } else if (key == 'dev') {
        filter.developers = value.split(':').toSet();
      } else if (key == 'pub') {
        filter.publishers = value.split(':').toSet();
      } else if (key == 'col') {
        filter.collections = value.split(':').toSet();
      } else if (key == 'frn') {
        filter.franchises = value.split(':').toSet();
      } else if (key == 'ggr') {
        filter.genreGroups = value.split(':').toSet();
      } else if (key == 'gnr') {
        filter.genres = value.split(':').toSet();
      } else if (key == 'kw') {
        filter.keywords = value.split(':').toSet();
      } else if (key == 'gnt') {
        filter.manualGenres = value.split(':').toSet();
      } else if (key == 'tag') {
        filter.userTags = value.split(':').toSet();
      }
    });
    return filter;
  }
}
