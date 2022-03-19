import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/store_entry.dart';

class LibraryEntry {
  final int id;
  final String name;
  final String? cover;

  final int releaseDate;

  final List<Annotation> collections;
  final List<Annotation> companies;

  final List<StoreEntry> storeEntries;
  final List<int> ownedVersions;

  GameUserData userData;

  LibraryEntry({
    required this.id,
    required this.name,
    this.cover,
    this.releaseDate = 0,
    this.collections = const [],
    this.companies = const [],
    this.storeEntries = const [],
    this.ownedVersions = const [],
    this.userData = const GameUserData(),
  });

  LibraryEntry.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          name: json['name']!,
          cover: json['cover'],
          releaseDate: json['release_date'] ?? 0,
          collections: json.containsKey('collections')
              ? [
                  for (final entry in json['collections'])
                    Annotation.fromJson(entry),
                ]
              : [],
          companies: json.containsKey('companies')
              ? [
                  for (final entry in json['companies'])
                    Annotation.fromJson(entry),
                ]
              : [],
          storeEntries: json.containsKey('store_entries')
              ? [
                  for (final entry in json['store_entries'])
                    StoreEntry.fromJson(entry),
                ]
              : [],
          ownedVersions: json.containsKey('owned_versions')
              ? [for (final version in json['owned_versions']) version]
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
      'release_date': releaseDate,
      if (collections.isNotEmpty)
        'collections': [
          for (final entry in collections) entry.toJson(),
        ],
      if (companies.isNotEmpty)
        'companies': [
          for (final entry in companies) entry.toJson(),
        ],
      if (storeEntries.isNotEmpty)
        'store_entries': [
          for (final entry in storeEntries) entry.toJson(),
        ],
      if (ownedVersions.isNotEmpty) 'owned_versions': ownedVersions,
      'user_data': userData.toJson(),
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
          tags: json.containsKey('tags')
              ? [for (final tag in json['tags']) tag]
              : [],
        );

  Map<String, dynamic> toJson() {
    return {
      if (tags.isNotEmpty) 'tags': tags,
    };
  }
}
