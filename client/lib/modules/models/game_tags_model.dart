import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/user_tags.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Index of tags extracted from user's library.
///
/// The index is computed on-the-fly in the client.
class GameTagsModel extends ChangeNotifier {
  SplayTreeSet<String> _stores = SplayTreeSet<String>();
  SplayTreeSet<String> _companies = SplayTreeSet<String>();
  SplayTreeSet<String> _collections = SplayTreeSet<String>();
  Map<String, List<int>> _tags = {};

  UnmodifiableListView<String> get stores => UnmodifiableListView(_stores);
  UnmodifiableListView<String> get companies =>
      UnmodifiableListView(_companies);
  UnmodifiableListView<String> get collections =>
      UnmodifiableListView(_collections);
  UnmodifiableListView<String> get tags => UnmodifiableListView(_tags.keys);

  Iterable<String> filterCompanies(Iterable<String> terms) {
    return companies.where((company) => terms.every((term) =>
        company.toLowerCase().split(' ').any((word) => word.startsWith(term))));
  }

  Iterable<String> filterStores(Iterable<String> terms) {
    return stores.where(
      (store) => terms.every((term) =>
          store.toLowerCase().split(' ').any((word) => word.startsWith(term))),
    );
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

  void update(String userId, List<LibraryEntry> entries) async {
    _tags.clear();
    for (final entry in entries) {
      _stores.addAll(entry.storeEntries.map((e) => e.storefront));
      _companies.addAll(entry.companies.map((company) => company));
      _collections.addAll(entry.collections.map((collection) => collection));
    }

    await _loadUserTags(userId);
    // NOTE: notifyListeners() happens on the user tags snapshot callback.
  }

  Future<void> _loadUserTags(String userId) async {
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('user_data')
        .doc('tags')
        .withConverter<UserTags>(
          fromFirestore: (snapshot, _) => UserTags.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .snapshots()
        .listen((DocumentSnapshot<UserTags> snapshot) {
      final user_tags = snapshot.data();
      if (user_tags == null) {
        notifyListeners();
        return;
      }

      for (final tag in user_tags.tags) {
        _tags[tag.name] = tag.gameIds;
      }
      notifyListeners();
    });
  }
}
