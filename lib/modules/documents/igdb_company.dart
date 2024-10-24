import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/game_entry.dart';

class IgdbCompany {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final GameImage? logo;

  final List<GameDigest> developed;
  final List<GameDigest> published;

  IgdbCompany({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logo,
    this.developed = const [],
    this.published = const [],
  });

  IgdbCompany.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          name: json['name']!,
          slug: json['slug']!,
          description: json['description'],
          logo: json.containsKey('logo')
              ? GameImage.fromJson(json['logo'])
              : null,
          developed: [
            for (final game in json['developed'] ?? [])
              GameDigest.fromJson(game),
          ],
          published: [
            for (final game in json['published'] ?? [])
              GameDigest.fromJson(game),
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (description != null) 'description': description,
      if (logo != null) 'logo': logo?.toJson(),
      if (developed.isNotEmpty)
        'developed': [
          for (final game in developed) game.toJson(),
        ],
      if (published.isNotEmpty)
        'published': [
          for (final game in published) game.toJson(),
        ],
    };
  }
}
