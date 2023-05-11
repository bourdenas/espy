import 'package:espy/modules/documents/game_digest.dart';

class IgdbCompany {
  final int id;
  final String name;
  final String? slug;
  final String? url;

  final List<GameDigest> developed;
  final List<GameDigest> published;

  IgdbCompany({
    required this.id,
    required this.name,
    this.slug,
    this.url,
    this.developed = const [],
    this.published = const [],
  });

  IgdbCompany.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          name: json['name']!,
          slug: json['slug'],
          url: json['url'],
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
      if (slug != null) 'slug': slug,
      if (url != null) 'url': url,
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
