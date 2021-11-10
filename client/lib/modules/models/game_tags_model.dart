import 'dart:collection';

import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class GameTagsIndex extends ChangeNotifier {
  Map<int, Annotation> _companies = {};
  Map<int, Annotation> _collections = {};
  SplayTreeSet<String> _tags = SplayTreeSet<String>();
  SplayTreeSet<String> _stores = SplayTreeSet<String>();

  UnmodifiableListView<Annotation> get companies =>
      UnmodifiableListView(_companies.values);
  UnmodifiableListView<Annotation> get collections =>
      UnmodifiableListView(_collections.values);
  UnmodifiableListView<String> get tags => UnmodifiableListView(_tags);
  UnmodifiableListView<String> get stores => UnmodifiableListView(_stores);

  void update(List<LibraryEntry> entries) {
    _tags.clear();
    for (final entry in entries) {
      _companies.addEntries(entry.companies.map((c) => MapEntry(c.id, c)));
      if (entry.collection != null)
        _collections[entry.collection!.id] = entry.collection!;
      _tags.addAll(entry.userData.tags);
      _stores.addAll(entry.storeEntries.map((e) => e.storefront));
    }

    notifyListeners();
  }
}

class GameTagsModel extends ChangeNotifier {
  GameTagsIndex? _index;
  String _searchPhrase = '';

  UnmodifiableListView<Annotation> get companies =>
      UnmodifiableListView(_index!.companies
          .where((c) => c.name.toLowerCase().contains(_searchPhrase)));
  UnmodifiableListView<Annotation> get collections =>
      UnmodifiableListView(_index!.collections
          .where((c) => c.name.toLowerCase().contains(_searchPhrase)));
  UnmodifiableListView<String> get tags => UnmodifiableListView(
      _index!.tags.where((tag) => tag.toLowerCase().contains(_searchPhrase)));
  UnmodifiableListView<String> get stores => UnmodifiableListView(_index!.stores
      .where((store) => store.toLowerCase().contains(_searchPhrase)));

  void update(GameTagsIndex index, String searchPhrase) {
    _index = index;
    _searchPhrase = searchPhrase;

    notifyListeners();
  }
}
