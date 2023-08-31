import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class LibraryFilterModel extends ChangeNotifier {
  LibraryFilter _filter = LibraryFilter();

  LibraryFilter get filter => _filter;

  set filter(LibraryFilter filter) {
    _filter = filter;
    notifyListeners();
  }
}

enum LibraryView {
  all,
  inLibrary,
  wishlist,
  untagged,
}

enum LibrarySorting {
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

class LibraryFilter {
  LibraryFilter({
    this.view = LibraryView.all,
    this.sorting = LibrarySorting.release,
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

  LibraryView view;
  LibrarySorting sorting;
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

  Iterable<LibraryEntry> filter(
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

    return _sort(gameIds
        .map((id) => entriesModel.getEntryById(id))
        .where((e) => e != null)
        .map((e) => e!)
        .where((e) =>
            e.digest.category == 'Main' ||
            e.digest.category == 'Remake' ||
            e.digest.category == 'Remaster' ||
            e.digest.category == 'StandaloneExpansion' ||
            (includeExpansions && e.digest.category == 'Expansion'))
        .where((libraryEntry) => _filterView(libraryEntry, tagsModel)));
  }

  Iterable<LibraryEntry> _sort(Iterable<LibraryEntry> entries) {
    switch (sorting) {
      case LibrarySorting.release:
        return entries.toList()
          ..sort((a, b) => -a.releaseDate.compareTo(b.releaseDate));
      case LibrarySorting.rating:
        return entries.toList()..sort((a, b) => -a.rating.compareTo(b.rating));
      case LibrarySorting.title:
        return entries.toList()..sort((a, b) => a.name.compareTo(b.name));
    }
  }

  bool _filterView(LibraryEntry entry, GameTagsModel tagsModel) {
    switch (view) {
      case LibraryView.all:
        return true;
      case LibraryView.inLibrary:
        return entry.storeEntries.isNotEmpty;
      case LibraryView.wishlist:
        return entry.storeEntries.isEmpty;
      case LibraryView.untagged:
        return tagsModel.userTags.byGameId(entry.id).isEmpty;
    }
  }

  Map<String, String> params() {
    return {
      'vw': _viewEncoding,
      'st': _sortingEncoding,
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
      } else if (key == 'st') {
        filter._sorting = value;
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
      case LibraryView.all:
        return 'all';
      case LibraryView.inLibrary:
        return 'lib';
      case LibraryView.wishlist:
        return 'wsl';
      case LibraryView.untagged:
        return 'unt';
      default:
        return 'all';
    }
  }

  set _view(String encoded) {
    switch (encoded) {
      case 'all':
        view = LibraryView.all;
        break;
      case 'lib':
        view = LibraryView.inLibrary;
        break;
      case 'wsl':
        view = LibraryView.wishlist;
        break;
      case 'unt':
        view = LibraryView.untagged;
        break;
    }
  }

  String get _sortingEncoding {
    switch (sorting) {
      case LibrarySorting.release:
        return 'yr';
      case LibrarySorting.rating:
        return 'rt';
      case LibrarySorting.title:
        return 'tl';
      default:
        return 'yr';
    }
  }

  set _sorting(String encoded) {
    switch (encoded) {
      case 'yr':
        sorting = LibrarySorting.release;
        break;
      case 'rt':
        sorting = LibrarySorting.rating;
        break;
      case 'tl':
        sorting = LibrarySorting.title;
        break;
      default:
        sorting = LibrarySorting.release;
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
