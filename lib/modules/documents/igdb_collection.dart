import 'package:espy/modules/documents/game_digest.dart';

class IgdbCollection {
  final int id;
  final String name;
  final String? slug;
  final String? url;

  final List<GameDigest> games;

  IgdbCollection({
    required this.id,
    required this.name,
    this.slug,
    this.url,
    this.games = const [],
  });

  IgdbCollection.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          name: json['name']!,
          slug: json['slug'],
          url: json['url'],
          games: [
            for (final game in json['games'] ?? []) GameDigest.fromJson(game),
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (slug != null) 'slug': slug,
      if (url != null) 'url': url,
      if (games.isNotEmpty)
        'games': [
          for (final game in games) game.toJson(),
        ],
    };
  }
}
