import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/library_entry.dart';

class LibraryFilter {
  String _titleSearchPhrase = '';
  Set<Annotation> companies = {};
  Set<Annotation> collections = {};
  Set<String> tags = {};
  Set<String> stores = {};

  bool get isActive =>
      _titleSearchPhrase.isNotEmpty ||
      companies.isNotEmpty ||
      collections.isNotEmpty ||
      tags.isNotEmpty ||
      stores.isNotEmpty;

  set titleSearchPhrase(String phrase) {
    _titleSearchPhrase = phrase;
  }

  bool apply(LibraryEntry entry) {
    return _filterCompany(entry) &&
        _filterCollection(entry) &&
        _filterTag(entry) &&
        _filterStore(entry) &&
        _filterTitle(entry);
  }

  void clear() {
    companies.clear();
    collections.clear();
    tags.clear();
    stores.clear();
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
    return entry.name.toLowerCase().contains(_titleSearchPhrase);
  }
}
