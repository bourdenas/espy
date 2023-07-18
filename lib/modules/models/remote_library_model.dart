import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/igdb_collection.dart';
import 'package:espy/modules/documents/igdb_company.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/library_filter_model.dart';

/// Model that handles LibraryEntries that are outside user's library.
class RemoteLibraryModel {
  static Future<List<LibraryEntry>> fromFilter(
    LibraryFilter filter, {
    bool includeExpansions = false,
  }) async {
    List<LibraryEntry> libraryEntries = [];

    if (filter.collections.isNotEmpty) {
      for (final collection in filter.collections) {
        libraryEntries
            .addAll(await getCollection(collection, includeExpansions));
      }
    }

    if (filter.franchises.isNotEmpty) {
      for (final franchise in filter.franchises) {
        libraryEntries.addAll(await getFranchise(franchise, includeExpansions));
      }
    }

    if (filter.developers.isNotEmpty) {
      for (final developer in filter.developers) {
        libraryEntries.addAll(await getDeveloper(developer, includeExpansions));
      }
    }

    if (filter.publishers.isNotEmpty) {
      for (final publisher in filter.publishers) {
        libraryEntries.addAll(await getPublisher(publisher, includeExpansions));
      }
    }

    return libraryEntries;
  }

  static Future<List<LibraryEntry>> getCollection(
    String name,
    bool includeExpansions,
  ) async {
    Map<int, LibraryEntry> libraryEntries = {};

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
        if (digest.category == 'Main' ||
            digest.category == 'Remake' ||
            digest.category == 'Remaster' ||
            digest.category == 'StandaloneExpansion' ||
            (includeExpansions && digest.category == 'Expansion')) {
          libraryEntries[digest.id] = LibraryEntry.fromGameDigest(digest);
        }
      }
    }

    return libraryEntries.values.toList();
  }

  static Future<List<LibraryEntry>> getFranchise(
    String name,
    bool includeExpansions,
  ) async {
    Map<int, LibraryEntry> libraryEntries = {};

    final snapshot = await FirebaseFirestore.instance
        .collection('franchises')
        .where('name', isEqualTo: name)
        .withConverter<IgdbCollection>(
          fromFirestore: (snapshot, _) =>
              IgdbCollection.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .get();

    for (final franchise in snapshot.docs) {
      for (final digest in franchise.data().games) {
        if (digest.category == 'Main' ||
            digest.category == 'Remake' ||
            digest.category == 'Remaster' ||
            digest.category == 'StandaloneExpansion' ||
            (includeExpansions && digest.category == 'Expansion')) {
          libraryEntries[digest.id] = LibraryEntry.fromGameDigest(digest);
        }
      }
    }

    return libraryEntries.values.toList();
  }

  static Future<List<LibraryEntry>> getDeveloper(
    String name,
    bool includeExpansions,
  ) async {
    Map<int, LibraryEntry> libraryEntries = {};

    final snapshot = await FirebaseFirestore.instance
        .collection('companies')
        .where('name', isEqualTo: name)
        .withConverter<IgdbCompany>(
          fromFirestore: (snapshot, _) =>
              IgdbCompany.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .get();

    for (final company in snapshot.docs) {
      for (final digest in company.data().developed) {
        if (digest.category == 'Main' ||
            digest.category == 'Remake' ||
            digest.category == 'Remaster' ||
            digest.category == 'StandaloneExpansion' ||
            (includeExpansions && digest.category == 'Expansion')) {
          libraryEntries[digest.id] = LibraryEntry.fromGameDigest(digest);
        }
      }
    }

    return libraryEntries.values.toList();
  }

  static Future<List<LibraryEntry>> getPublisher(
    String name,
    bool includeExpansions,
  ) async {
    Map<int, LibraryEntry> libraryEntries = {};

    final snapshot = await FirebaseFirestore.instance
        .collection('companies')
        .where('name', isEqualTo: name)
        .withConverter<IgdbCompany>(
          fromFirestore: (snapshot, _) =>
              IgdbCompany.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .get();

    for (final company in snapshot.docs) {
      for (final digest in company.data().published) {
        if (digest.category == 'Main' ||
            digest.category == 'Remake' ||
            digest.category == 'Remaster' ||
            digest.category == 'StandaloneExpansion' ||
            (includeExpansions && digest.category == 'Expansion')) {
          libraryEntries[digest.id] = LibraryEntry.fromGameDigest(digest);
        }
      }
    }

    return libraryEntries.values.toList();
  }
}
