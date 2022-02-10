import 'dart:collection';

import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Index of tags extracted from user's library.
///
/// The index is computed on-the-fly in the client.
class GameTagsModel extends ChangeNotifier {
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

  Iterable<Annotation> filterCompanies(Iterable<String> terms) {
    return companies.where((company) => terms.every((term) => company.name
        .toLowerCase()
        .split(' ')
        .any((word) => word.startsWith(term))));
  }

  Iterable<Annotation> filterCollections(Iterable<String> terms) {
    return collections.where((collection) => terms.every((term) => collection
        .name
        .toLowerCase()
        .split(' ')
        .any((word) => word.startsWith(term))));
  }

  Iterable<String> filterTags(Iterable<String> terms) {
    return tags.where(
      (tag) => terms.every((term) =>
          tag.toLowerCase().split(' ').any((word) => word.startsWith(term))),
    );
  }

  Iterable<String> filterStores(Iterable<String> terms) {
    return stores.where(
      (store) => terms.every((term) =>
          store.toLowerCase().split(' ').any((word) => word.startsWith(term))),
    );
  }

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
