import 'package:espy/modules/documents/store_entry.dart';

class RecentEntry {
  final int libraryEntryId;
  final int addedTimestamp;
  final StoreEntry storeEntry;

  RecentEntry({
    required this.libraryEntryId,
    required this.addedTimestamp,
    required this.storeEntry,
  });

  RecentEntry.fromJson(Map<String, dynamic> json)
      : this(
          libraryEntryId: json['library_entry_id']!,
          addedTimestamp: json['added_timestamp']!,
          storeEntry: StoreEntry.fromJson(json['store_entry']!),
        );

  Map<String, dynamic> toJson() {
    return {
      'library_entry_id': libraryEntryId,
      'added_timestamp': addedTimestamp,
      'store_entry': storeEntry.toJson(),
    };
  }
}

class Recent {
  final List<RecentEntry> entries;

  const Recent({this.entries = const []});

  Recent.fromJson(Map<String, dynamic> json)
      : this(entries: [
          for (final entry in json['entries'] ?? [])
            RecentEntry.fromJson(entry),
        ]);

  Map<String, dynamic> toJson() {
    return {
      'entries': [
        for (final entry in entries) entry.toJson(),
      ],
    };
  }
}
