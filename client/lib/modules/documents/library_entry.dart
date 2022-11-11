import 'package:espy/modules/documents/store_entry.dart';

class LibraryEntry {
  final int id;
  final String name;
  final String? cover;

  final int releaseDate;

  final List<String> collections;
  final List<String> companies;

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
          collections: [
            for (final collection in json['collections'] ?? []) collection,
          ],
          companies: [
            for (final company in json['companies'] ?? []) company,
          ],
          storeEntries: [
            for (final entry in json['store_entries'] ?? [])
              StoreEntry.fromJson(entry),
          ],
          ownedVersions: [
            for (final version in json['owned_versions'] ?? []) version
          ],
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
      if (collections.isNotEmpty) 'collections': collections,
      if (companies.isNotEmpty) 'companies': companies,
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
          tags: [for (final tag in json['tags'] ?? []) tag],
        );

  Map<String, dynamic> toJson() {
    return {
      if (tags.isNotEmpty) 'tags': tags,
    };
  }
}
