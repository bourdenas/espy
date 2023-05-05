import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/igdb_collection.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model that handles LibraryEntries that are outside user's library.
class RemoteLibraryModel extends ChangeNotifier {
  final List<LibraryEntry> _libraryEntries = const [];

  Iterable<LibraryEntry> get entries => _libraryEntries;

  Future<void> getCollection(String name) async {
    _libraryEntries.clear();

    final snapshot = await FirebaseFirestore.instance
        .collection('collections')
        .where('name', isEqualTo: name)
        .withConverter<IgdbCollection>(
          fromFirestore: (snapshot, _) =>
              IgdbCollection.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .get();

    for (final collection in snapshot.docs) {
      for (final digest in collection.data().games) {
        _libraryEntries.add(LibraryEntry.fromGameDigest(digest));
      }
    }

    notifyListeners();
  }

  void clear() {
    _libraryEntries.clear();
    notifyListeners();
  }
}
