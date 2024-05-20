import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/store_entry.dart';

class UnresolvedEntries {
  final List<Unresolved> needApproval;
  final List<StoreEntry> unknown;

  UnresolvedEntries({
    this.needApproval = const [],
    this.unknown = const [],
  });

  UnresolvedEntries.fromJson(Map<String, dynamic> json)
      : this(needApproval: [
          for (final entry in json['need_approval'] ?? [])
            Unresolved.fromJson(entry),
        ], unknown: [
          for (final entry in json['unknown'] ?? []) StoreEntry.fromJson(entry),
        ]);

  Map<String, dynamic> toJson() {
    return {
      if (needApproval.isNotEmpty)
        'need_approval': [
          for (final entry in needApproval) entry.toJson(),
        ],
      if (unknown.isNotEmpty)
        'unknown': [
          for (final entry in unknown) entry.toJson(),
        ]
    };
  }
}

class Unresolved {
  final StoreEntry storeEntry;
  final List<GameDigest> candidates;

  const Unresolved({
    required this.storeEntry,
    this.candidates = const [],
  });

  Unresolved.fromJson(Map<String, dynamic> json)
      : this(
          storeEntry: StoreEntry.fromJson(json['store_entry']!),
          candidates: [
            for (final entry in json['candidates'] ?? [])
              GameDigest.fromJson(entry),
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'store_entry': storeEntry,
      if (candidates.isNotEmpty)
        'candidates': [
          for (final entry in candidates) entry.toJson(),
        ],
    };
  }
}
