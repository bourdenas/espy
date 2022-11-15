import 'package:espy/modules/documents/steam_data.dart';

class GameEntry {
  final int id;
  final String name;

  final String summary;
  final String storyline;
  final int releaseDate;
  final double igdbRating;

  final List<String> genres;
  final List<String> keywords;

  final List<GameEntry> expansions;
  final List<GameEntry> dlcs;
  final List<GameEntry> remakes;
  final List<GameEntry> remasters;
  final List<int> versions;
  final int? parent;

  final List<Collection> collections;
  final List<Company> companies;

  final GameImage? cover;
  final List<GameImage> screenshots;
  final List<GameImage> artwork;
  final List<Website> websites;

  final SteamData? steamData;

  const GameEntry({
    required this.id,
    required this.name,
    this.summary = '',
    this.storyline = '',
    this.releaseDate = 0,
    this.igdbRating = 0.0,
    this.genres = const [],
    this.keywords = const [],
    this.expansions = const [],
    this.dlcs = const [],
    this.remakes = const [],
    this.remasters = const [],
    this.versions = const [],
    this.parent = null,
    this.collections = const [],
    this.companies = const [],
    this.cover,
    this.screenshots = const [],
    this.artwork = const [],
    this.websites = const [],
    this.steamData = null,
  });

  GameEntry.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          name: json['name']!,
          summary: json['summary'] ?? '',
          storyline: json['storyline'] ?? '',
          releaseDate: json['release_date'] ?? 0,
          igdbRating: json['igdb_rating'] ?? 0,
          genres: [
            for (final genre in json['genres'] ?? []) genre,
          ],
          keywords: [
            for (final kw in json['keywords'] ?? []) kw,
          ],
          expansions: [
            for (final entry in json['expansions'] ?? [])
              GameEntry.fromJson(entry),
          ],
          dlcs: [
            for (final entry in json['dlcs'] ?? []) GameEntry.fromJson(entry),
          ],
          remakes: [
            for (final entry in json['remakes'] ?? [])
              GameEntry.fromJson(entry),
          ],
          remasters: [
            for (final entry in json['remasters'] ?? [])
              GameEntry.fromJson(entry),
          ],
          versions: [for (final version in json['versions'] ?? []) version],
          parent: json['parent'],
          collections: [
            for (final entry in json['collections'] ?? [])
              Collection.fromJson(entry),
          ],
          companies: [
            for (final entry in json['companies'] ?? [])
              Company.fromJson(entry),
          ],
          cover: json.containsKey('cover')
              ? GameImage.fromJson(json['cover'])
              : null,
          screenshots: [
            for (final entry in json['screenshots'] ?? [])
              GameImage.fromJson(entry),
          ],
          artwork: [
            for (final entry in json['artwork'] ?? [])
              GameImage.fromJson(entry),
          ],
          websites: [
            for (final entry in json['websites'] ?? []) Website.fromJson(entry),
          ],
          steamData: json.containsKey('steam_data')
              ? SteamData.fromJson(json['steam_data'])
              : null,
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (summary.isNotEmpty) 'summary': summary,
      if (storyline.isNotEmpty) 'storyline': storyline,
      if (releaseDate > 0) 'release_date': releaseDate,
      if (igdbRating > 0.0) 'igdb_rating': igdbRating,
      if (genres.isNotEmpty) 'genres': genres,
      if (keywords.isNotEmpty) 'keywords': keywords,
      if (expansions.isNotEmpty)
        'expansions': [
          for (final entry in expansions) entry.toJson(),
        ],
      if (dlcs.isNotEmpty)
        'dlcs': [
          for (final entry in dlcs) entry.toJson(),
        ],
      if (remakes.isNotEmpty)
        'remakes': [
          for (final entry in remakes) entry.toJson(),
        ],
      if (remasters.isNotEmpty)
        'remasters': [
          for (final entry in remasters) entry.toJson(),
        ],
      if (versions.isNotEmpty) 'versions': versions,
      if (parent != null) 'parent': parent,
      if (collections.isNotEmpty)
        'collections': [
          for (final entry in collections) entry.toJson(),
        ],
      if (companies.isNotEmpty)
        'companies': [
          for (final entry in companies) entry.toJson(),
        ],
      if (cover != null) 'cover': cover!.toJson(),
      if (screenshots.isNotEmpty)
        'screenshots': [
          for (final entry in screenshots) entry.toJson(),
        ],
      if (artwork.isNotEmpty)
        'artwork': [
          for (final entry in artwork) entry.toJson(),
        ],
      if (websites.isNotEmpty)
        'websites': [
          for (final entry in websites) entry.toJson(),
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

class Company {
  final int id;
  final String name;
  final String slug;
  final String role;
  final GameImage? logo;

  const Company({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
    this.logo,
  });

  Company.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id'],
          name: json['name'],
          slug: json['slug'],
          role: json['role'],
          logo: json.containsKey('logo')
              ? GameImage.fromJson(json['logo'])
              : null,
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'role': role,
      if (logo != null) 'logo': logo!.toJson(),
    };
  }
}

class Collection {
  final int id;
  final String name;
  final String slug;
  final String igdbType;

  const Collection({
    required this.id,
    required this.name,
    required this.slug,
    required this.igdbType,
  });

  Collection.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id'],
          name: json['name'],
          slug: json['slug'],
          igdbType: json['igdb_type'],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'igdb_type': igdbType,
    };
  }
}

class Website {
  final String url;
  final String authority;

  const Website({
    required this.url,
    required this.authority,
  });

  Website.fromJson(Map<String, dynamic> json)
      : this(
          url: json['url'],
          authority: json['authority'],
        );

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'authority': authority,
    };
  }
}
