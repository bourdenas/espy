import 'dart:collection';

import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Index of tags extracted from user's library.
///
/// The index is computed on-the-fly in the client.
class GameTagsModel extends ChangeNotifier {
  SplayTreeSet<String> _companies = SplayTreeSet<String>();
  SplayTreeSet<String> _collections = SplayTreeSet<String>();
  SplayTreeSet<String> _tags = SplayTreeSet<String>();
  SplayTreeSet<String> _stores = SplayTreeSet<String>();

  UnmodifiableListView<String> get companies =>
      UnmodifiableListView(_companies);
  UnmodifiableListView<String> get collections =>
      UnmodifiableListView(_collections);
  UnmodifiableListView<String> get tags => UnmodifiableListView(_tags);
  UnmodifiableListView<String> get stores => UnmodifiableListView(_stores);

  Iterable<String> filterCompanies(Iterable<String> terms) {
    return companies.where((company) => terms.every((term) =>
        company.toLowerCase().split(' ').any((word) => word.startsWith(term))));
  }

  Iterable<String> filterCollections(Iterable<String> terms) {
    return collections.where((collection) => terms.every((term) => collection
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
      _companies.addAll(entry.companies.map((c) => c.name));
      _collections.addAll(entry.collections.map((c) => c.name));
      _tags.addAll(entry.userData.tags);
      _stores.addAll(entry.storeEntries.map((e) => e.storefront));
    }

    notifyListeners();
  }
}
