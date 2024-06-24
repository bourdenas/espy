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

  Iterable<LibraryEntry> get entries => _libraryEntries;

  bool _fetchExternal = false;
  LibraryFilter _filter = LibraryFilter();

  Future<void> update(
    AppConfigModel appConfig,
    LibraryIndexModel libraryIndexModel,
    LibraryFilter filter,
  ) async {
    if (_fetchExternal == appConfig.showExternal.value &&
        _filter.equals(filter)) {
      // Nothing of interest changed.
      return;
    }
    _fetchExternal = appConfig.showExternal.value;
    _filter = LibraryFilter.fromParams(filter.params());

    _libraryEntries.clear();

    if (libraryIndexModel.isNotEmpty && !appConfig.showExternal.value) {
      return;
    }

    List<List<LibraryEntry>> fetchedEntries = [];

    if (filter.collection != null) {
      fetchedEntries.add(await _getCollection(filter.collection!));
    }

    if (filter.franchise != null) {
      fetchedEntries.add(await _getFranchise(filter.franchise!));
    }

    if (filter.developer != null) {
      fetchedEntries.add(await _getDeveloper(filter.developer!));
    }

    if (filter.publisher != null) {
      fetchedEntries.add(await _getPublisher(filter.publisher!));
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
