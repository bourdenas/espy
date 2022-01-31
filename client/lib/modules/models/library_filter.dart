import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/library_entry.dart';

class LibraryFilter {
  LibraryFilter({
    this.titleSearch = '',
    this.companies = const {},
    this.collections = const {},
    this.tags = const {},
    this.stores = const {},
  });

  String titleSearch;
  Set<Annotation> companies;
  Set<Annotation> collections;
  Set<String> tags;
  Set<String> stores;

  bool get isNotEmpty =>
      titleSearch.isNotEmpty ||
      companies.isNotEmpty ||
      collections.isNotEmpty ||
      tags.isNotEmpty ||
      stores.isNotEmpty;

  bool apply(LibraryEntry entry) {
    return _filterCompany(entry) &&
        _filterCollection(entry) &&
        _filterTag(entry) &&
        _filterStore(entry) &&
        _filterTitle(entry);
  }

  String encode() {
    return [
      companies.map((c) => 'cmp=${c.id}').join('+'),
      collections.map((c) => 'col=${c.id}').join('+'),
      tags.map((tag) => 'tag=$tag').join('+'),
      stores.map((store) => 'str=$store').join('+'),
    ].where((param) => param.isNotEmpty).join('+');
  }

  factory LibraryFilter.decode(String encodedFilter) {
    final companies = Set<Annotation>();
    final collections = Set<Annotation>();
    final tags = Set<String>();
    final stores = Set<String>();

    final segments = encodedFilter.split('+');
    for (final segment in segments) {
      final term = segment.split('=');
      if (term.length != 2) {
        continue;
      }

      if (term[0] == 'cmp') {
        companies.add(Annotation(id: int.tryParse(term[1]) ?? 0, name: ''));
      } else if (term[0] == 'col') {
        collections.add(Annotation(id: int.tryParse(term[1]) ?? 0, name: ''));
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
    );
  }

  bool _filterCompany(LibraryEntry entry) {
    return companies.isEmpty ||
        companies.every((filter) =>
            entry.companies.any((company) => company.id == filter.id));
  }

  bool _filterCollection(LibraryEntry entry) {
    return collections.isEmpty ||
        collections.every((filter) => filter.id == entry.collection?.id);
  }

  bool _filterTag(LibraryEntry entry) {
    return tags.isEmpty ||
        tags.every((filter) => entry.userData.tags.contains(filter));
  }

  bool _filterStore(LibraryEntry entry) {
    return stores.isEmpty ||
        stores.every((filter) =>
            entry.storeEntries.any((store) => store.storefront == filter));
  }

  bool _filterTitle(LibraryEntry entry) {
    return entry.name.toLowerCase().contains(titleSearch);
  }
}
