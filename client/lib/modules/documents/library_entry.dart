import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/store_entry.dart';

class LibraryEntry {
  final int id;
  final String name;
  final int releaseDate;
  final String? cover;

  final Annotation? collection;
  final List<Annotation> franchises;
  final List<Annotation> companies;

  final List<StoreEntry> storeEntries;

  GameUserData userData;

  LibraryEntry({
    required this.id,
    required this.name,
    this.cover,
    this.releaseDate = 0,
    this.collection,
    this.franchises = const [],
    this.companies = const [],
    this.storeEntries = const [],
    this.userData = const GameUserData(),
  });

  LibraryEntry.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          name: json['name']!,
          releaseDate: json['release_date'] ?? 0,
          cover: json['cover'],
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
          storeEntries: json.containsKey('store_entry')
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
      'release_date': releaseDate,
      if (cover != null) 'cover': cover,
      if (collection != null) 'collection': collection!.toJson(),
      if (franchises.isNotEmpty)
        'franchises': [
          for (final entry in franchises) entry.toJson(),
        ],
      if (companies.isNotEmpty)
        'companies': [
          for (final entry in companies) entry.toJson(),
        ],
      if (storeEntries.isNotEmpty)
        'store_entry': [
          for (final entry in storeEntries) entry.toJson(),
        ],
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
