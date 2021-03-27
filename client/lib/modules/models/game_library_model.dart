import 'dart:collection';
import 'dart:convert';

import 'package:espy/constants/urls.dart';
import 'package:espy/proto/igdbapi.pb.dart' show Collection, Company;
import 'package:espy/proto/library.pb.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:http/http.dart' as http;

class GameLibraryModel extends ChangeNotifier {
  Library _library = Library.create();
  LibraryFilter _filter = LibraryFilter();

  UnmodifiableListView<GameEntry> get games =>
      UnmodifiableListView(_library.entry.where((e) => _filter.apply(e)));

  LibraryFilter get filter => _filter;

  void fetch() async {
    final response =
        await http.get(Uri.parse('${Urls.espyBackend}/library/testing'));

    if (response.statusCode == 200) {
      final lib = Library.fromBuffer(response.bodyBytes);
      _update(lib);
    } else {
      throw Exception('Failed to load game library');
    }
  }

  void postDetails(GameEntry entry) async {
    var response = await http.post(
      Uri.parse('${Urls.espyBackend}/library/testing/details/${entry.game.id}'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'tags': entry.details.tag,
      }),
    );
    if (response.statusCode != 200) {
      print('postDetails (error): $response');
    }
  }

  set titleFilter(String phrase) {
    if (phrase == _filter.titlePhrase) {
      return;
    }
    _filter.titlePhrase = phrase;
    notifyListeners();
  }

  set companyFilter(Company company) {
    _filter.company = company;
    notifyListeners();
  }

  set collectionFilter(Collection collection) {
    _filter.collection = collection;
    notifyListeners();
  }

  set tag(String tag) {
    _filter.tag = tag;
    notifyListeners();
  }

  void clearFilter() {
    _filter.clear();
    notifyListeners();
  }

  GameEntry? getEntryById(String id) {
    final gameId = int.tryParse(id);
    if (gameId == null) {
      return null;
    }

    for (final entry in _library.entry) {
      if (entry.game.id == gameId) {
        return entry;
      }
    }
    return null;
  }

  /// Updates the model with new entries from input [Library].
  void _update(Library lib) {
    _library = lib;
    _library.entry.sort((a, b) => -a.game.firstReleaseDate.seconds
        .compareTo(b.game.firstReleaseDate.seconds));
    notifyListeners();
  }

  /// Removes all games from the model.
  void clear() {
    _library.clear();
    notifyListeners();
  }
}

class LibraryFilter {
  String _titlePhrase = '';
  Company? company;
  Collection? collection;
  String? tag;

  String get titlePhrase {
    return _titlePhrase;
  }

  set titlePhrase(String phrase) {
    _titlePhrase = phrase.toLowerCase();
  }

  bool apply(GameEntry entry) {
    return _filterCompany(entry) &&
        _filterCollection(entry) &&
        _filterTag(entry) &&
        _filterTitle(entry);
  }

  void clear() {
    _titlePhrase = '';
    company = null;
    collection = null;
    tag = null;
  }

  bool _filterCompany(GameEntry entry) {
    return company == null ||
        entry.game.involvedCompanies.any((e) => e.company.id == company!.id);
  }

  bool _filterCollection(GameEntry entry) {
    return collection == null || entry.game.collection.id == collection!.id;
  }

  bool _filterTag(GameEntry entry) {
    return tag == null || entry.details.tag.contains(tag);
  }

  bool _filterTitle(GameEntry entry) {
    return entry.game.name.toLowerCase().contains(_titlePhrase);
  }
}
