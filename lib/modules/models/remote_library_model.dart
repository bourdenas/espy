import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/igdb_collection.dart';
import 'package:espy/modules/documents/igdb_company.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model that handles LibraryEntries that are outside user's library.
class RemoteLibraryModel extends ChangeNotifier {
  final List<LibraryEntry> _libraryEntries = [];

  Iterable<LibraryEntry> get entries =>
      _libraryEntries.where((entry) => entry.isMainGame);
  Iterable<LibraryEntry> get entriesWithExpansions =>
      _libraryEntries.where((entry) => entry.isMainGame || entry.isExpansion);

  Future<void> update(AppConfigModel appConfig, LibraryFilter filter) async {
    _libraryEntries.clear();

    if (!appConfig.showOutOfLib.value) {
      return;
    }

    print('fetching remote: ${filter.params()}');

    if (filter.collections.isNotEmpty) {
      for (final collection in filter.collections) {
        _libraryEntries.addAll(await _getCollection(collection));
      }
    }

    if (filter.franchises.isNotEmpty) {
      for (final franchise in filter.franchises) {
        _libraryEntries.addAll(await _getFranchise(franchise));
      }
    }

    if (filter.developers.isNotEmpty) {
      for (final developer in filter.developers) {
        _libraryEntries.addAll(await _getDeveloper(developer));
      }
    }

    if (filter.publishers.isNotEmpty) {
      for (final publisher in filter.publishers) {
        _libraryEntries.addAll(await _getPublisher(publisher));
      }
    }

    notifyListeners();
  }

  static Future<List<LibraryEntry>> _getCollection(String name) async {
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
        libraryEntries[digest.id] = LibraryEntry.fromGameDigest(digest);
      }
    }

    return libraryEntries.values.toList();
  }

  static Future<List<LibraryEntry>> _getFranchise(String name) async {
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
        libraryEntries[digest.id] = LibraryEntry.fromGameDigest(digest);
      }
    }

    return libraryEntries.values.toList();
  }

  static Future<List<LibraryEntry>> _getDeveloper(String name) async {
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
        libraryEntries[digest.id] = LibraryEntry.fromGameDigest(digest);
      }
    }

    return libraryEntries.values.toList();
  }

  static Future<List<LibraryEntry>> _getPublisher(String name) async {
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
        libraryEntries[digest.id] = LibraryEntry.fromGameDigest(digest);
      }
    }

    return libraryEntries.values.toList();
  }
}
