class UserTags {
  List<TagClass> classes;

  UserTags({
    this.classes = const [],
  }) {
    if (classes.isEmpty) {
      classes = [
        TagClass(name: 'genre'),
        TagClass(name: 'style'),
        TagClass(name: 'theme'),
        TagClass(name: 'other'),
      ];
    }
  }

  UserTags.fromJson(Map<String, dynamic> json)
      : this(
          classes: [
            // ignore: no_leading_underscores_for_local_identifiers
            for (final _class in json['classes'] ?? [])
              TagClass.fromJson(_class),
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      'classes': [
        // ignore: no_leading_underscores_for_local_identifiers
        for (final _class in classes) _class.toJson(),
      ],
    };
  }
}

class TagClass {
  final String name;
  List<Tag> tags = [];

  TagClass({
    required this.name,
    this.tags = const [],
  }) {
    if (tags.isEmpty) {
      tags = [];
    }
  }

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
