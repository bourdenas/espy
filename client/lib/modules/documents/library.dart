import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';

class Library {
  final List<LibraryEntry> entries;

  Library(this.entries);

  Library.fromJson(Map<String, dynamic> json)
      : this(
          json.containsKey('entries')
              ? [
                  for (final entry in json['entries'])
                    LibraryEntry.fromJson(entry),
                ]
              : [],
        );

  Map<String, dynamic> toJson() {
    return {
      if (entries.isNotEmpty)
        'entries': [
          for (final entry in entries) entry.toJson(),
        ],
    };
  }
}

class FailedEntries {
  final List<StoreEntry> entries;

  FailedEntries(this.entries);

  FailedEntries.fromJson(Map<String, dynamic> json)
      : this(
          json.containsKey('entries')
              ? [
                  for (final entry in json['entries'])
                    StoreEntry.fromJson(entry),
                ]
              : [],
        );

  Map<String, dynamic> toJson() {
    return {
      if (entries.isNotEmpty)
        'entries': [
          for (final entry in entries) entry.toJson(),
        ],
    };
  }
}
