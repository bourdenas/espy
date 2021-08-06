import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class LibraryFiltersModel extends ChangeNotifier {
  LibraryFilter _filter = LibraryFilter();

  void update(String searchPhrase) {
    _filter.titleSearchPhrase = searchPhrase;
    notifyListeners();
  }

  LibraryFilter get filter => _filter;

  void addCompanyFilter(Annotation company) {
    _filter.companies.add(company);
    notifyListeners();
  }

  void removeCompanyFilter(Annotation company) {
    _filter.companies.remove(company);
    notifyListeners();
  }

  void addCollectionFilter(Annotation collection) {
    _filter.collections.add(collection);
    notifyListeners();
  }

  void removeCollectionFilter(Annotation collection) {
    _filter.collections.remove(collection);
    notifyListeners();
  }

  void addTagFilter(String tag) {
    _filter.tags.add(tag);
    notifyListeners();
  }

  void removeTagFilter(String tag) {
    _filter.tags.remove(tag);
    notifyListeners();
  }

  void clearFilter() {
    _filter.clear();
    notifyListeners();
  }
}

class LibraryFilter {
  String _titleSearchPhrase = '';
  Set<Annotation> companies = {};
  Set<Annotation> collections = {};
  Set<String> tags = {};

  set titleSearchPhrase(String phrase) {
    _titleSearchPhrase = phrase;
  }

  bool apply(LibraryEntry entry) {
    return _filterCompany(entry) &&
        _filterCollection(entry) &&
        _filterTag(entry) &&
        _filterTitle(entry);
  }

  void clear() {
    companies.clear();
    collections.clear();
    tags.clear();
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

  bool _filterTitle(LibraryEntry entry) {
    return entry.name.toLowerCase().contains(_titleSearchPhrase);
  }
}
