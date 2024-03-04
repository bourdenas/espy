import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/modules/documents/igdb_collection.dart';
import 'package:espy/modules/documents/igdb_company.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_index_model.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

/// Model that handles LibraryEntries that are outside user's library.
class RemoteLibraryModel extends ChangeNotifier {
  final List<LibraryEntry> _libraryEntries = [];

  Iterable<LibraryEntry> get entries =>
      _libraryEntries.where((entry) => entry.isStandaloneGame);
  Iterable<LibraryEntry> get entriesWithExpansions => _libraryEntries
      .where((entry) => entry.isStandaloneGame || entry.isExpansion);

  Future<void> update(
    AppConfigModel appConfig,
    LibraryIndexModel libraryIndexModel,
    LibraryFilter filter,
  ) async {
    _libraryEntries.clear();

    if (libraryIndexModel.entries.isNotEmpty && !appConfig.showOutOfLib.value) {
      return;
    }

    List<List<LibraryEntry>> fetchedEntries = [];

    if (filter.collections.isNotEmpty) {
      for (final collection in filter.collections) {
        fetchedEntries.add(await _getCollection(collection));
      }
    }

    if (filter.franchises.isNotEmpty) {
      for (final franchise in filter.franchises) {
        fetchedEntries.add(await _getFranchise(franchise));
      }
    }

    if (filter.developers.isNotEmpty) {
      for (final developer in filter.developers) {
        fetchedEntries.add(await _getDeveloper(developer));
      }
    }

    if (filter.publishers.isNotEmpty) {
      for (final publisher in filter.publishers) {
        fetchedEntries.add(await _getPublisher(publisher));
      }
    }

    final idSets = fetchedEntries
        .map((entries) => Set<int>.from(entries.map((e) => e.id)));
    if (idSets.isNotEmpty) {
      final intersection = idSets.reduce((a, b) => a.intersection(b));
      _libraryEntries.addAll(fetchedEntries.first
          .where((e) => intersection.contains(e.id))
          .where((e) => libraryIndexModel.getEntryById(e.id) == null)
          .toList());
    }

    notifyListeners();
  }

  static Future<List<LibraryEntry>> _getCollection(String name) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('collections')
        .where('name', isEqualTo: name)
        .withConverter<IgdbCollection>(
          fromFirestore: (snapshot, _) =>
              IgdbCollection.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .get();

    final libraryEntries = <LibraryEntry>[];
    for (final collection in snapshot.docs) {
      for (final digest in collection.data().games) {
        libraryEntries.add(LibraryEntry.fromGameDigest(digest));
      }
    }
    return libraryEntries;
  }

  static Future<List<LibraryEntry>> _getFranchise(String name) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('franchises')
        .where('name', isEqualTo: name)
        .withConverter<IgdbCollection>(
          fromFirestore: (snapshot, _) =>
              IgdbCollection.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .get();

    final libraryEntries = <LibraryEntry>[];
    for (final franchise in snapshot.docs) {
      for (final digest in franchise.data().games) {
        libraryEntries.add(LibraryEntry.fromGameDigest(digest));
      }
    }
    return libraryEntries;
  }

  static Future<List<LibraryEntry>> _getDeveloper(String name) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('companies')
        .where('name', isEqualTo: name)
        .withConverter<IgdbCompany>(
          fromFirestore: (snapshot, _) =>
              IgdbCompany.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .get();

    final libraryEntries = <LibraryEntry>[];
    for (final company in snapshot.docs) {
      for (final digest in company.data().developed) {
        libraryEntries.add(LibraryEntry.fromGameDigest(digest));
      }
    }
    return libraryEntries;
  }

  static Future<List<LibraryEntry>> _getPublisher(String name) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('companies')
        .where('name', isEqualTo: name)
        .withConverter<IgdbCompany>(
          fromFirestore: (snapshot, _) =>
              IgdbCompany.fromJson(snapshot.data()!),
          toFirestore: (entry, _) => entry.toJson(),
        )
        .get();

    final libraryEntries = <LibraryEntry>[];
    for (final company in snapshot.docs) {
      for (final digest in company.data().published) {
        libraryEntries.add(LibraryEntry.fromGameDigest(digest));
      }
    }
    return libraryEntries;
  }
}
