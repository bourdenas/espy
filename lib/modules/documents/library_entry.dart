import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';

class LibraryEntry {
  final int id;
  final GameDigest digest;

  final int addedDate;
  final List<StoreEntry> storeEntries;

  String get name => digest.name;
  String? get cover => digest.cover;
  int get releaseDate => digest.releaseDate;
  double get rating => digest.rating;
  List<String> get collections => digest.collections;
  List<String> get franchises => digest.franchises;
  List<String> get developers => digest.developers;
  List<String> get publishers => digest.publishers;

  bool get isMainGame =>
      digest.category == 'Main' ||
      digest.category == 'Remake' ||
      digest.category == 'Remaster' ||
      digest.category == 'StandaloneExpansion';
  bool get isExpansion => digest.category == 'Expansion';

  LibraryEntry({
    required this.id,
    required this.digest,
    this.addedDate = 0,
    this.storeEntries = const [],
  });

  LibraryEntry.fromGameDigest(GameDigest digest)
      : this(
          id: digest.id,
          digest: digest,
        );

  LibraryEntry.fromGameEntry(GameEntry gameEntry)
      : this(
          id: gameEntry.id,
          digest: GameDigest.fromGameEntry(gameEntry),
        );

  LibraryEntry.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          digest: GameDigest.fromJson(json['digest']!),
          addedDate: json['added_date'] ?? 0,
          storeEntries: [
            for (final entry in json['store_entries'] ?? [])
              StoreEntry.fromJson(entry),
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'digest': digest.toJson(),
      if (addedDate > 0) 'added_date': addedDate,
      if (storeEntries.isNotEmpty)
        'store_entries': [
          for (final entry in storeEntries) entry.toJson(),
        ],
    };
  }
}
