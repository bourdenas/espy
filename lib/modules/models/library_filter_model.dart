import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class LibraryFilterModel extends ChangeNotifier {
  LibraryFilter filter = LibraryFilter();

  void update(AppConfigModel appConfig) {
    print('updating with ${appConfig.libraryGrouping.value}');
    if (appConfig.libraryGrouping.value != filter.grouping) {
      filter.grouping = appConfig.libraryGrouping.value;
      notifyListeners();
    }
  }
}

enum LibraryClass {
  all,
  inLibrary,
  wishlist,
  untagged,
}

enum LibraryOrdering {
  release,
  rating,
  title,
}

enum LibraryGrouping {
  none,
  year,
  genre,
  genreTag,
  rating,
}

class LibraryView {
  final List<(String, List<LibraryEntry>)> groups;

  const LibraryView(this.groups);

  // Returns a flat view of all groups in the view.
  Iterable<LibraryEntry> get all => groups.expand((e) => e.$2);

  int get length => groups.fold(0, (len, group) => len + group.$2.length);

  bool get hasGroups => groups.length > 1 || groups.first.$1.isNotEmpty;
}

class LibraryFilter {
  LibraryFilter({
    this.view = LibraryClass.all,
    this.ordering = LibraryOrdering.release,
    this.grouping = LibraryGrouping.none,
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

  LibraryClass view;
  LibraryOrdering ordering;
  LibraryGrouping grouping;

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

  LibraryView filter(
    LibraryEntriesModel entriesModel,
    GameTagsModel tagsModel, {
    bool includeExpansions = false,
  }) {
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
    for (final keyword in keywords) {
      gameIdSets.add(Set.from(tagsModel.keywords.gameIds(keyword)));
    }
    for (final tag in tags) {
      gameIdSets.add(Set.from(tagsModel.userTags.gameIds(tag)));
    }

    final gameIds = gameIdSets.isNotEmpty
        ? gameIdSets.reduce((value, element) => value.intersection(element))
        : entriesModel.all;

    return LibraryView(_group(_sort(gameIds
        .map((id) => entriesModel.getEntryById(id))
        .where((e) => e != null)
        .map((e) => e!)
        .where((e) =>
            e.digest.category == 'Main' ||
            e.digest.category == 'Remake' ||
            e.digest.category == 'Remaster' ||
            e.digest.category == 'StandaloneExpansion' ||
            (includeExpansions && e.digest.category == 'Expansion'))
        .where((libraryEntry) => _filterView(libraryEntry, tagsModel)))));
  }

  List<LibraryEntry> _sort(Iterable<LibraryEntry> entries) {
    switch (ordering) {
      case LibraryOrdering.release:
        return entries.toList()
          ..sort((a, b) => -a.releaseDate.compareTo(b.releaseDate));
      case LibraryOrdering.rating:
        return entries.toList()..sort((a, b) => -a.rating.compareTo(b.rating));
      case LibraryOrdering.title:
        return entries.toList()..sort((a, b) => a.name.compareTo(b.name));
    }
  }

  List<(String, List<LibraryEntry>)> _group(List<LibraryEntry> entries) {
    switch (grouping) {
      case LibraryGrouping.none:
        return [('', entries)];
      case LibraryGrouping.year:
        return groupBy(
            entries,
            (e) =>
                '${DateTime.fromMillisecondsSinceEpoch(e.releaseDate * 1000).year}',
            (a, b) => -a.compareTo(b));
      case LibraryGrouping.genre:
        return groupBy(entries, (e) => e.digest.genres[0]);
      case LibraryGrouping.genreTag:
        return groupBy(entries, (e) => e.digest.genres[0]);
      case LibraryGrouping.rating:
        return groupBy(entries,
            (e) => (5 * e.digest.rating / 100.0).toStringAsFixed(1).toString());
    }
  }

  List<(String, List<LibraryEntry>)> groupBy(
      Iterable<LibraryEntry> entries, String Function(LibraryEntry) key,
      [int Function(String, String)? keyCompare]) {
    var groups = <String, List<LibraryEntry>>{};
    for (final entry in entries) {
      (groups[key(entry)] ??= []).add(entry);
    }

    final keys = groups.keys.toList()..sort(keyCompare);
    return keys
        .map((key) => (key, groups[key]))
        .whereType<(String, List<LibraryEntry>)>()
        .toList();
  }

  bool _filterView(LibraryEntry entry, GameTagsModel tagsModel) {
    switch (view) {
      case LibraryClass.all:
        return true;
      case LibraryClass.inLibrary:
        return entry.storeEntries.isNotEmpty;
      case LibraryClass.wishlist:
        return entry.storeEntries.isEmpty;
      case LibraryClass.untagged:
        return tagsModel.userTags.byGameId(entry.id).isEmpty;
    }
  }

  Map<String, String> params() {
    return {
      'vw': _viewEncoding,
      'rd': _orderingEncoding,
      if (grouping != LibraryGrouping.none) 'gp': _groupingEncoding,
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
      if (key == 'vw') {
        filter._view = value;
      } else if (key == 'rd') {
        filter._ordering = value;
      } else if (key == 'gp') {
        filter._grouping = value;
      } else if (key == 'dev') {
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

  String get _viewEncoding {
    switch (view) {
      case LibraryClass.all:
        return 'all';
      case LibraryClass.inLibrary:
        return 'lib';
      case LibraryClass.wishlist:
        return 'wsl';
      case LibraryClass.untagged:
        return 'unt';
      default:
        return 'all';
    }
  }

  set _view(String encoded) {
    switch (encoded) {
      case 'all':
        view = LibraryClass.all;
        break;
      case 'lib':
        view = LibraryClass.inLibrary;
        break;
      case 'wsl':
        view = LibraryClass.wishlist;
        break;
      case 'unt':
        view = LibraryClass.untagged;
        break;
    }
  }

  String get _orderingEncoding {
    switch (ordering) {
      case LibraryOrdering.release:
        return 'yr';
      case LibraryOrdering.rating:
        return 'rt';
      case LibraryOrdering.title:
        return 'tl';
      default:
        return 'yr';
    }
  }

  set _ordering(String encoded) {
    switch (encoded) {
      case 'yr':
        ordering = LibraryOrdering.release;
        break;
      case 'rt':
        ordering = LibraryOrdering.rating;
        break;
      case 'tl':
        ordering = LibraryOrdering.title;
        break;
      default:
        ordering = LibraryOrdering.release;
    }
  }

  String get _groupingEncoding {
    switch (grouping) {
      case LibraryGrouping.none:
        return 'na';
      case LibraryGrouping.year:
        return 'yr';
      case LibraryGrouping.genre:
        return 'gn';
      case LibraryGrouping.genreTag:
        return 'gt';
      case LibraryGrouping.rating:
        return 'rt';
      default:
        return 'na';
    }
  }

  set _grouping(String encoded) {
    switch (encoded) {
      case 'na':
        grouping = LibraryGrouping.none;
        break;
      case 'yr':
        grouping = LibraryGrouping.year;
        break;
      case 'gn':
        grouping = LibraryGrouping.genre;
        break;
      case 'gt':
        grouping = LibraryGrouping.genreTag;
        break;
      case 'rt':
        grouping = LibraryGrouping.rating;
        break;
      default:
        grouping = LibraryGrouping.none;
    }
  }
}
