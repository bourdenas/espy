import 'dart:collection';
import 'dart:convert';

import 'package:espy/proto/library.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const String BACKEND_HOST = 'localhost:3030';
// const String BACKEND_HOST = '10.0.2.2:3030';

class GameLibraryModel extends ChangeNotifier {
  Library _library = Library.create();
  _LibraryFilter _filter = _LibraryFilter();

  UnmodifiableListView<GameEntry> get games =>
      UnmodifiableListView(_library.entry.where((e) => _filter.apply(e)));

  void fetch() async {
    final response = await http.get(Uri.http(BACKEND_HOST, 'library/testing'));

    if (response.statusCode == 200) {
      final lib = Library.fromBuffer(response.bodyBytes);
      _update(lib);
    } else {
      throw Exception('Failed to load game library');
    }
  }

  void postDetails(GameEntry entry) async {
    var response = await http.post(
      Uri.http(BACKEND_HOST, '/library/testing/details/${entry.game.id}'),
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

  set companyFilter(Int64 id) {
    _filter.companyId = id;
    notifyListeners();
  }

  set collectionFilter(Int64 id) {
    _filter.collectionId = id;
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

class _LibraryFilter {
  String get titlePhrase {
    return _titlePhrase;
  }

  set titlePhrase(String phrase) {
    _titlePhrase = phrase.toLowerCase();
  }

  set companyId(Int64 id) {
    clear();
    _companyId = id;
  }

  set collectionId(Int64 id) {
    clear();
    _collectionId = id;
  }

  set tag(String tag) {
    clear();
    _tag = tag;
  }

  bool apply(GameEntry entry) {
    return _filterCompany(entry) &&
        _filterCollection(entry) &&
        _filterTag(entry) &&
        _filterTitle(entry);
  }

  void clear() {
    _titlePhrase = '';
    _companyId = null;
    _collectionId = null;
    _tag = null;
  }

  String _titlePhrase = '';
  Int64? _companyId;
  Int64? _collectionId;
  String? _tag;

  bool _filterCompany(GameEntry entry) {
    return _companyId == null ||
        entry.game.involvedCompanies.any((e) => e.company.id == _companyId);
  }

  bool _filterCollection(GameEntry entry) {
    return _collectionId == null || entry.game.collection.id == _collectionId;
  }

  bool _filterTag(GameEntry entry) {
    return _tag == null || entry.details.tag.contains(_tag);
  }

  bool _filterTitle(GameEntry entry) {
    return entry.game.name.toLowerCase().contains(_titlePhrase);
  }
}
