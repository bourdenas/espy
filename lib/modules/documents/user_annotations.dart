class UserAnnotations {
  List<Genre> genres;
  List<UserTag> userTags;

  UserAnnotations({
    this.genres = const [],
    this.userTags = const [],
  });

  UserAnnotations.fromJson(Map<String, dynamic> json)
      : this(
          genres: [
            for (final genre in json['genres'] ?? []) Genre.fromJson(genre),
          ],
          userTags: [
            for (final tag in json['user_tags'] ?? []) UserTag.fromJson(tag),
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'genres': [
        for (final genre in genres) genre.toJson(),
      ],
      'user_tags': [
        for (final tag in userTags) tag.toJson(),
      ],
    };
  }
}

class Genre {
  final String name;
  final List<int> gameIds;

  Genre({
    required this.name,
    this.gameIds = const [],
  });

  String encode() => name;

  static decode(String encoded) {
    return Genre(name: encoded);
  }

  Genre.fromJson(Map<String, dynamic> json)
      : this(
          name: json['name']!,
          gameIds: [
            for (int id in json['game_ids'] ?? []) id,
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'game_ids': gameIds,
    };
  }
}

class UserTag {
  final String name;
  final List<int> gameIds;

  UserTag(
    this.name, {
    required this.gameIds,
  });

  UserTag.fromJson(Map<String, dynamic> json)
      : this(
          json['name']!,
          gameIds: [
            for (int id in json['game_ids'] ?? []) id,
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'game_ids': gameIds,
    };
  }
}