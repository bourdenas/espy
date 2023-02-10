import 'package:espy/modules/documents/library_entry.dart';

enum LibraryView {
  ALL,
  IN_LIBRARY,
  WISHLIST,
  UNTAGGED,
}

class LibraryFilter {
  LibraryFilter({
    this.view = LibraryView.IN_LIBRARY,
    this.companies = const {},
    this.collections = const {},
    this.tags = const {},
    this.stores = const {},
  });

  LibraryView view;

  Set<String> companies;
  Set<String> collections;
  Set<String> tags;
  Set<String> stores;

  bool get isEmpty => !isNotEmpty;

  bool get isNotEmpty =>
      companies.isNotEmpty ||
      collections.isNotEmpty ||
      tags.isNotEmpty ||
      stores.isNotEmpty;

  bool apply(LibraryEntry entry) =>
      _filterView(entry) &&
      _filterStore(entry) &&
      _filterCompany(entry) &&
      _filterCollection(entry);

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

  bool _filterView(LibraryEntry entry) {
    switch (view) {
      case LibraryView.ALL:
        return true;
      case LibraryView.IN_LIBRARY:
        return entry.storeEntries.isNotEmpty;
      case LibraryView.WISHLIST:
        return entry.storeEntries.isEmpty;
      case LibraryView.UNTAGGED:
        return false;
    }
  }

  bool _filterStore(LibraryEntry entry) =>
      stores.isEmpty ||
      stores.every((filter) =>
          entry.storeEntries.any((store) => store.storefront == filter));

  bool _filterCompany(LibraryEntry entry) =>
      companies.isEmpty ||
      companies.every(
          (filter) => entry.companies.any((company) => company == filter));

  bool _filterCollection(LibraryEntry entry) =>
      collections.isEmpty ||
      collections.every((filter) =>
          entry.collections.any((collection) => collection == filter));
}
