class UserTags {
  final List<Tag> tags;

  UserTags({
    required this.tags,
  });

  UserTags.fromJson(Map<String, dynamic> json)
      : this(
          tags: [
            for (final tag in json['tags'] ?? []) Tag.fromJson(tag),
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'tags': [
        for (final tag in tags) tag.toJson(),
      ],
    };
  }
}

class Tag {
  final String name;
  final List<int> gameIds;

  Tag({
    required this.name,
    required this.gameIds,
  });

  Tag.fromJson(Map<String, dynamic> json)
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
