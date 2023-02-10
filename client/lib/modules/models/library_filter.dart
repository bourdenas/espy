import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';

enum LibraryView {
  ALL,
  IN_LIBRARY,
  WISHLIST,
  UNTAGGED,
}

class LibraryFilter {
  LibraryFilter({
    this.view = LibraryView.IN_LIBRARY,
    this.stores = const {},
    this.companies = const {},
    this.collections = const {},
    this.tags = const {},
  });

  LibraryView view;

  Set<String> stores;
  Set<String> companies;
  Set<String> collections;
  Set<String> tags;

  Iterable<LibraryEntry> filter(
      GameEntriesModel entriesModel, GameTagsModel tagsModel) {
    List<Set<int>> gameIdSets = [];

    for (final store in stores) {
      gameIdSets.add(Set.from(tagsModel.stores.gameIds(store)));
    }
    for (final company in companies) {
      gameIdSets.add(Set.from(tagsModel.companies.gameIds(company)));
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
        .where((libraryEntry) => _filterView(libraryEntry, tagsModel));
  }

  bool _filterView(LibraryEntry entry, GameTagsModel tagsModel) {
    switch (view) {
      case LibraryView.ALL:
        return true;
      case LibraryView.IN_LIBRARY:
        return entry.storeEntries.isNotEmpty;
      case LibraryView.WISHLIST:
        return entry.storeEntries.isEmpty;
      case LibraryView.UNTAGGED:
        return tagsModel.userTags.byGameId(entry.id).isEmpty;
    }
  }

  Map<String, String> params() {
    return {
      'vw': _viewEncoding,
      if (companies.isNotEmpty) 'cmp': companies.map((c) => c).join(','),
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
      } else if (key == 'cmp') {
        filter.companies = value.split(',').toSet();
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
      case LibraryView.ALL:
        return 'all';
      case LibraryView.IN_LIBRARY:
        return 'lib';
      case LibraryView.WISHLIST:
        return 'wsl';
      case LibraryView.UNTAGGED:
        return 'unt';
      default:
        return 'all';
    }
  }

  set _view(String encoded) {
    switch (encoded) {
      case 'all':
        view = LibraryView.ALL;
        break;
      case 'lib':
        view = LibraryView.IN_LIBRARY;
        break;
      case 'wsl':
        view = LibraryView.WISHLIST;
        break;
      case 'unt':
        view = LibraryView.UNTAGGED;
        break;
    }
  }
}
