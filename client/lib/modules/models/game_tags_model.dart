import 'dart:collection';

import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

class GameTagsIndex extends ChangeNotifier {
  Set<Annotation> _companies = {};
  Set<Annotation> _collections = {};
  SplayTreeSet<String> _tags = SplayTreeSet<String>();

  UnmodifiableListView<Annotation> get companies =>
      UnmodifiableListView(_companies);
  UnmodifiableListView<Annotation> get collections =>
      UnmodifiableListView(_collections);
  UnmodifiableListView<String> get tags => UnmodifiableListView(_tags);

  void update(List<LibraryEntry> entries) {
    _tags.clear();
    for (final entry in entries) {
      _companies.addAll(entry.companies);
      if (entry.collection != null) _collections.add(entry.collection!);
      _tags.addAll(entry.userData.tags);
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

  void update(GameTagsIndex index, String searchPhrase) {
    _index = index;
    _searchPhrase = searchPhrase;

    notifyListeners();
  }
}
