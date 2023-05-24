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

class LibraryFilter {
  LibraryFilter({
    this.view = LibraryView.all,
    this.stores = const {},
    this.developers = const {},
    this.publishers = const {},
    this.collections = const {},
    this.tags = const {},
  });

  LibraryView view;

  Set<String> stores;
  Set<String> developers;
  Set<String> publishers;
  Set<String> collections;
  Set<String> tags;

  LibraryFilter add(LibraryFilter other) {
    return LibraryFilter(
      stores: stores.union(other.stores),
      developers: developers.union(other.developers),
      publishers: publishers.union(other.publishers),
      collections: collections.union(other.collections),
      tags: tags.union(other.tags),
    );
  }

  LibraryFilter remove(LibraryFilter other) {
    return LibraryFilter(
      stores: stores.difference(other.stores),
      developers: developers.difference(other.developers),
      publishers: publishers.difference(other.publishers),
      collections: collections.difference(other.collections),
      tags: tags.difference(other.tags),
    );
  }

  bool contains(LibraryFilter other) {
    return other.stores.difference(stores).isEmpty &&
        other.developers.difference(developers).isEmpty &&
        other.publishers.difference(publishers).isEmpty &&
        other.collections.difference(collections).isEmpty &&
        other.tags.difference(tags).isEmpty;
  }

  Iterable<LibraryEntry> filter(
      LibraryEntriesModel entriesModel, GameTagsModel tagsModel) {
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
    for (final tag in tags) {
      gameIdSets.add(Set.from(tagsModel.userTags.gameIds(tag)));
    }

    final gameIds = gameIdSets.isNotEmpty
        ? gameIdSets.reduce((value, element) => value.intersection(element))
        : entriesModel.all;

    return gameIds
        .map((id) => entriesModel.getEntryById(id))
        .where((e) => e != null)
        .map((e) => e!)
        .where((e) =>
            e.digest.category == 'Main' ||
            e.digest.category == 'Remake' ||
            e.digest.category == 'Remaster')
        .where((libraryEntry) => _filterView(libraryEntry, tagsModel));
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
      if (developers.isNotEmpty) 'dev': developers.map((c) => c).join(','),
      if (publishers.isNotEmpty) 'pub': publishers.map((c) => c).join(','),
      if (collections.isNotEmpty) 'col': collections.map((c) => c).join(','),
      if (tags.isNotEmpty) 'tag': tags.map((t) => t).join(','),
      if (stores.isNotEmpty) 'str': stores.map((s) => s).join(','),
    };
  }

  factory LibraryFilter.fromParams(Map<String, String> params) {
    var filter = LibraryFilter();

    params.forEach((key, value) {
      if (key == 'vw') {
        filter._view = value;
      } else if (key == 'dev') {
        filter.developers = value.split(',').toSet();
      } else if (key == 'pub') {
        filter.publishers = value.split(',').toSet();
      } else if (key == 'col') {
        filter.collections = value.split(',').toSet();
      } else if (key == 'tag') {
        filter.tags = value.split(',').toSet();
      } else if (key == 'str') {
        filter.stores = value.split(',').toSet();
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
}
