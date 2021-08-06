import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:fixnum/fixnum.dart';

class LibraryEntry {
  final Int64 id;
  final String name;
  final String? cover;
  final Int64? releaseDate;

  final Annotation? collection;
  final List<Annotation> franchises;
  final List<Annotation> companies;

  final List<StoreEntry> storeEntry;

  final GameUserData userData;

  const LibraryEntry({
    required this.id,
    required this.name,
    this.cover,
    this.releaseDate,
    this.collection,
    this.franchises = const [],
    this.companies = const [],
    this.storeEntry = const [],
    this.userData = const GameUserData(),
  });

  LibraryEntry.fromJson(Map<String, dynamic> json)
      : this(
          id: Int64(json['id']!),
          name: json['name']!,
          cover: json['cover'],
          releaseDate: Int64(json['release_date'] ?? 0),
          collection: json.containsKey('collection')
              ? Annotation.fromJson(json['collection'])
              : null,
          franchises: json.containsKey('franchises')
              ? [
                  for (final entry in json['franchises'])
                    Annotation.fromJson(entry),
                ]
              : [],
          companies: json.containsKey('companies')
              ? [
                  for (final entry in json['companies'])
                    Annotation.fromJson(entry),
                ]
              : [],
          storeEntry: json.containsKey('store_entry')
              ? [
                  for (final entry in json['store_entry'])
                    StoreEntry.fromJson(entry),
                ]
              : [],
          userData: json.containsKey('user_data')
              ? GameUserData.fromJson(json['user_data'])
              : GameUserData(),
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (cover != null) 'cover': cover,
      if (releaseDate != null) 'release_date': releaseDate,
      if (collection != null) 'collection': collection,
      if (franchises.isNotEmpty)
        'store_entry': [
          for (final entry in franchises) entry.toJson(),
        ],
      if (companies.isNotEmpty)
        'store_entry': [
          for (final entry in companies) entry.toJson(),
        ],
      if (storeEntry.isNotEmpty)
        'store_entry': [
          for (final entry in storeEntry) entry.toJson(),
        ],
      'userData': userData.toJson(),
    };
  }
}

class GameUserData {
  final List<String> tags;

  const GameUserData({
    this.tags = const [],
  });

  GameUserData.fromJson(Map<String, dynamic> json)
      : this(
          tags: json['tags'],
        );

  Map<String, dynamic> toJson() {
    return {
      'tags': tags,
    };
  }
}
