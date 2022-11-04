import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/library_entry.dart';

class LibraryFilter {
  LibraryFilter({
    this.titleSearch = '',
    this.companies = const {},
    this.collections = const {},
    this.tags = const {},
    this.stores = const {},
    this.untagged = false,
  });

  String titleSearch;
  Set<String> companies;
  Set<String> collections;
  Set<String> tags;
  Set<String> stores;
  bool untagged;

  bool get isEmpty => !isNotEmpty;

  bool get isNotEmpty =>
      titleSearch.isNotEmpty ||
      companies.isNotEmpty ||
      collections.isNotEmpty ||
      tags.isNotEmpty ||
      stores.isNotEmpty ||
      untagged;

  bool apply(LibraryEntry entry) =>
      _filterCompany(entry) &&
      _filterCollection(entry) &&
      _filterTag(entry) &&
      _filterStore(entry) &&
      _filterTitle(entry) &&
      _filterUntagged(entry);

  String encode() {
    return [
      companies.map((company) => 'cmp=${company}').join('+'),
      collections.map((collection) => 'col=${collection}').join('+'),
      tags.map((tag) => 'tag=$tag').join('+'),
      stores.map((store) => 'str=$store').join('+'),
      if (untagged) 'untagged',
    ].where((param) => param.isNotEmpty).join('+');
  }

  Map<String, String> params() {
    return {
      if (companies.isNotEmpty) 'cmp': companies.map((c) => c).join(','),
      if (collections.isNotEmpty) 'col': collections.map((c) => c).join(','),
      if (tags.isNotEmpty) 'tag': tags.map((t) => t).join(','),
      if (stores.isNotEmpty) 'str': stores.map((s) => s).join(','),
      if (untagged) 'untagged': '',
    };
  }

  factory LibraryFilter.fromParams(Map<String, String> params) {
    var filter = LibraryFilter();

    params.forEach((key, value) {
      if (key == 'cmp') {
        filter.companies = value.split(',').toSet();
      } else if (key == 'col') {
        filter.collections = value.split(',').toSet();
      } else if (key == 'tag') {
        filter.tags = value.split(',').toSet();
      } else if (key == 'str') {
        filter.stores = value.split(',').toSet();
      } else if (key == 'untagged') {
        filter.untagged = true;
      }
    });
    return filter;
  }

  factory LibraryFilter.decode(String encodedFilter) {
    final companies = Set<String>();
    final collections = Set<String>();
    final tags = Set<String>();
    final stores = Set<String>();
    var untagged = false;

    final segments = encodedFilter.split('+');
    for (final segment in segments) {
      final term = segment.split('=');
      if (term[0] == 'untagged') {
        untagged = true;
      }

      if (term.length != 2) {
        continue;
      }

      if (term[0] == 'cmp') {
        companies.add(term[1]);
      } else if (term[0] == 'col') {
        collections.add(term[1]);
      } else if (term[0] == 'tag') {
        tags.add(term[1]);
      } else if (term[0] == 'str') {
        stores.add(term[1]);
      }
    }

    return LibraryFilter(
      companies: companies,
      collections: collections,
      tags: tags,
      stores: stores,
      untagged: untagged,
    );
  }

  bool _filterCompany(LibraryEntry entry) =>
      companies.isEmpty ||
      companies.every(
          (filter) => entry.companies.any((company) => company.name == filter));

  bool _filterCollection(LibraryEntry entry) =>
      collections.isEmpty ||
      collections.every((filter) =>
          entry.collections.any((collection) => collection.name == filter));

  bool _filterTag(LibraryEntry entry) =>
      tags.isEmpty ||
      tags.every((filter) => entry.userData.tags.contains(filter));

  bool _filterStore(LibraryEntry entry) =>
      stores.isEmpty ||
      stores.every((filter) =>
          entry.storeEntries.any((store) => store.storefront == filter));

  bool _filterTitle(LibraryEntry entry) =>
      entry.name.toLowerCase().contains(titleSearch);

  bool _filterUntagged(LibraryEntry entry) =>
      !untagged || entry.userData.tags.isEmpty;
}
