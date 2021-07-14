import 'dart:collection';
import 'dart:convert';

import 'package:espy/constants/urls.dart';
import 'package:espy/proto/igdbapi.pb.dart' as igdb;
import 'package:espy/proto/library.pb.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:http/http.dart' as http;

class GameDetailsModel extends ChangeNotifier {
  Set<igdb.Company> _companies = {};
  Set<igdb.Collection> _collections = {};
  SplayTreeSet<String> _tags = SplayTreeSet<String>();
  String _searchPhrase = '';
  String _userId = '';

  UnmodifiableListView<igdb.Company> get companies => UnmodifiableListView(
      _companies.where((c) => c.name.toLowerCase().contains(_searchPhrase)));
  UnmodifiableListView<igdb.Collection> get collections => UnmodifiableListView(
      _collections.where((c) => c.name.toLowerCase().contains(_searchPhrase)));

  UnmodifiableListView<String> get tags => UnmodifiableListView(
      _tags.where((tag) => tag.toLowerCase().contains(_searchPhrase)));
  UnmodifiableListView<String> get allTags => UnmodifiableListView(_tags);

  void update(String userId, Library library, String searchPhrase) {
    if (userId != _userId || _searchPhrase == searchPhrase) {
      // Poor man's approach to avoid costly reindexing. I'd rather have updates
      // per dependency.
      _updateIndex(library);
    }
    _userId = userId;
    _searchPhrase = searchPhrase;

    notifyListeners();
  }

  Future<void> _updateIndex(Library library) async {
    _tags.clear();
    for (final entry in library.entry) {
      _companies.addAll(entry.game.involvedCompanies
          .where((ic) => ic.developer)
          .map((ic) => ic.company));
      _collections.add(entry.game.collection);
      _tags.addAll(entry.details.tag);
    }
  }

  void postDetails(GameEntry entry) async {
    entry.details.tag.sort();

    var response = await http.post(
      Uri.parse(
          '${Urls.espyBackend}/library/$_userId/details/${entry.game.id}'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'tags': entry.details.tag,
      }),
    );

    if (response.statusCode != 200) {
      print('postDetails (error): $response');
    } else {
      _tags.addAll(entry.details.tag);
      notifyListeners();
    }
  }
}
