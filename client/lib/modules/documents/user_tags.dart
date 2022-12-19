class UserTags {
  final List<TagClass> classes;

  UserTags({
    required this.classes,
  });

  UserTags.fromJson(Map<String, dynamic> json)
      : this(
          classes: [
            for (final _class in json['classes'] ?? [])
              TagClass.fromJson(_class),
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'classes': [
        for (final _class in classes) _class.toJson(),
      ],
    };
  }
}

class TagClass {
  final String name;
  final List<Tag> tags;

  TagClass({
    required this.name,
    required this.tags,
  });

  TagClass.fromJson(Map<String, dynamic> json)
      : this(
          name: json['name'] ?? '',
          tags: [
            for (final tag in json['tags'] ?? []) Tag.fromJson(tag),
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      if (name.isNotEmpty) 'name': name,
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
