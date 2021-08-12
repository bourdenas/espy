import 'package:espy/modules/documents/annotation.dart';

class GameEntry {
  final int id;
  final String name;

  final String summary;
  final int releaseDate;

  final Annotation? collection;
  final List<Annotation> franchises;
  final List<Annotation> companies;

  final GameImage? cover;
  final List<GameImage> screenshots;
  final List<GameImage> artwork;

  const GameEntry({
    required this.id,
    required this.name,
    this.summary = '',
    this.releaseDate = 0,
    this.collection,
    this.franchises = const [],
    this.companies = const [],
    this.cover,
    this.screenshots = const [],
    this.artwork = const [],
  });

  GameEntry.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          name: json['name']!,
          summary: json['summary'] ?? '',
          releaseDate: json['release_date'] ?? 0,
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
          cover: json.containsKey('cover')
              ? GameImage.fromJson(json['cover'])
              : null,
          screenshots: json.containsKey('screenshots')
              ? [
                  for (final entry in json['screenshots'])
                    GameImage.fromJson(entry),
                ]
              : [],
          artwork: json.containsKey('artwork')
              ? [
                  for (final entry in json['artwork'])
                    GameImage.fromJson(entry),
                ]
              : [],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (summary.isNotEmpty) 'summary': summary,
      if (releaseDate != null) 'release_date': releaseDate,
      if (collection != null) 'collection': collection!.toJson(),
      if (franchises.isNotEmpty)
        'franchises': [
          for (final entry in franchises) entry.toJson(),
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
