import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';

class Library {
  final List<LibraryEntry> entries;

  const Library({this.entries = const []});

  Library.fromJson(Map<String, dynamic> json)
      : this(entries: [
          for (final entry in json['entries'] ?? [])
            LibraryEntry.fromJson(entry),
        ]);

  Map<String, dynamic> toJson() {
    return {
      'entries': [
        for (final entry in entries) entry.toJson(),
      ],
    };
  }
}

class FailedEntries {
  final List<StoreEntry> entries;

  FailedEntries({this.entries = const []});

  FailedEntries.fromJson(Map<String, dynamic> json)
      : this(entries: [
          for (final entry in json['entries'] ?? []) StoreEntry.fromJson(entry),
        ]);

  Map<String, dynamic> toJson() {
    return {
      'entries': [
        for (final entry in entries) entry.toJson(),
      ],
    };
  }
}
