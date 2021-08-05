import 'package:espy/modules/documents/store_entry.dart';
import 'package:fixnum/fixnum.dart';

class LibraryEntry {
  final Int64 id;
  final String name;
  final String? cover;
  final Int64? releaseDate;

  final Collection? collection;
  final List<Franchise> franchises;
  final List<Company> companies;

  final List<StoreEntry> storeEntry;

  final GameDetails details;
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
    this.details = const GameDetails(),
    this.userData = const GameUserData(),
  });

  LibraryEntry.fromJson(Map<String, dynamic> json)
      : this(
          id: Int64(json['id']!),
          name: json['name']!,
          cover: json['cover'],
          releaseDate: json['release_date'],
          collection: json.containsKey('collection')
              ? Collection.fromJson(json['collection'])
              : null,
          franchises: json.containsKey('franchises')
              ? [
                  for (final entry in json['franchises'])
                    Franchise.fromJson(entry),
                ]
              : [],
          companies: json.containsKey('companies')
              ? [
                  for (final entry in json['companies'])
                    Company.fromJson(entry),
                ]
              : [],
          storeEntry: json.containsKey('store_entry')
              ? [
                  for (final entry in json['store_entry'])
                    StoreEntry.fromJson(entry),
                ]
              : [],
          details: json.containsKey('details')
              ? GameDetails.fromJson(json['details'])
              : GameDetails(),
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
      'details': details.toJson(),
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

class Collection {
  final Int64 id;
  final String name;

  const Collection({
    required this.id,
    required this.name,
  });

  Collection.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id'],
          name: json['name'],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Franchise {
  final Int64 id;
  final String name;

  const Franchise({
    required this.id,
    required this.name,
  });

  Franchise.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id'],
          name: json['name'],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class Company {
  final Int64 id;
  final String name;

  const Company({
    required this.id,
    required this.name,
  });

  Company.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id'],
          name: json['name'],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class GameDetails {
  final String summary;
  final List<GameImage> screenshots;

  const GameDetails({
    this.summary = "",
    this.screenshots = const [],
  });

  GameDetails.fromJson(Map<String, dynamic> json)
      : this(
          summary: json['summary'],
          screenshots: [
            for (final entry in json['screenshots']) GameImage.fromJson(entry),
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      if (screenshots.isNotEmpty)
        'screenshots': [
          for (final entry in screenshots) entry.toJson(),
        ],
    };
  }
}

class GameImage {
  final String imageId;
  final int height;
  final int width;

  const GameImage({
    required this.imageId,
    required this.height,
    required this.width,
  });

  GameImage.fromJson(Map<String, dynamic> json)
      : this(
          imageId: json['image_id'],
          height: json['height'],
          width: json['width'],
        );

  Map<String, dynamic> toJson() {
    return {
      'image_id': imageId,
      'height': height,
      'width': width,
    };
  }
}
