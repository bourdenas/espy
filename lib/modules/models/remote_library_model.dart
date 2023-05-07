import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/igdb_collection.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/library_filter_model.dart';

/// Model that handles LibraryEntries that are outside user's library.
class RemoteLibraryModel {
  static Future<List<LibraryEntry>> fromFilter(LibraryFilter filter) async {
    List<LibraryEntry> libraryEntries = [];
    if (filter.collections.isNotEmpty) {
      for (final collection in filter.collections) {
        libraryEntries.addAll(await getCollection(collection));
      }
    }
    return libraryEntries;
  }

  static Future<List<LibraryEntry>> getCollection(String name) async {
    List<LibraryEntry> libraryEntries = [];

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
        if (digest.category == 'Main') {
          libraryEntries.add(LibraryEntry.fromGameDigest(digest));
        }
      }
    }

    return libraryEntries;
  }
}
