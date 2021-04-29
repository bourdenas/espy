import 'dart:collection';

import 'package:espy/proto/igdbapi.pb.dart' show Collection, Company;
import 'package:espy/proto/library.pb.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class GameEntriesModel extends ChangeNotifier {
  List<GameEntry> _entries = [];
  LibraryFilter _filter = LibraryFilter();

  UnmodifiableListView<GameEntry> get games =>
      UnmodifiableListView(_entries.where((e) => _filter.apply(e)));

  void update(Library library, String searchPhrase) {
    _entries = library.entry;
    _filter.titleSearchPhrase = searchPhrase;
    notifyListeners();
  }

  GameEntry? getEntryById(String id) {
    final gameId = int.tryParse(id);
    if (gameId == null) {
      return null;
    }

    for (final entry in _entries) {
      if (entry.game.id == gameId) {
        return entry;
      }
    }
    return null;
  }

  LibraryFilter get filter => _filter;

  void addCompanyFilter(Company company) {
    _filter.companies.add(company);
    notifyListeners();
  }

  void removeCompanyFilter(Company company) {
    _filter.companies.remove(company);
    notifyListeners();
  }

  void addCollectionFilter(Collection collection) {
    _filter.collections.add(collection);
    notifyListeners();
  }

  void removeCollectionFilter(Collection collection) {
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
  Set<Company> companies = {};
  Set<Collection> collections = {};
  Set<String> tags = {};

  set titleSearchPhrase(String phrase) {
    _titleSearchPhrase = phrase;
  }

  bool apply(GameEntry entry) {
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

  bool _filterCompany(GameEntry entry) {
    return companies.isEmpty ||
        companies.every((company) => entry.game.involvedCompanies
            .any((ic) => ic.developer && company.id == ic.company.id));
  }

  bool _filterCollection(GameEntry entry) {
    return collections.isEmpty ||
        collections.every((collection) => collection == entry.game.collection);
  }

  bool _filterTag(GameEntry entry) {
    return tags.isEmpty || tags.every((tag) => entry.details.tag.contains(tag));
  }

  bool _filterTitle(GameEntry entry) {
    return entry.game.name.toLowerCase().contains(_titleSearchPhrase);
  }
}
