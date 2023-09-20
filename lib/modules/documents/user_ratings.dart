class UserRatings {
  Map<int, int> ratings = {};

  UserRatings({
    required this.ratings,
  });

  UserRatings.fromJson(Map<String, dynamic> json)
      : this(
          ratings: {}..addEntries([
              for (final genre in json['ratings'] ?? [])
                MapEntry(genre['id'], genre['rt'])
            ]),
        );

  Map<String, dynamic> toJson() {
    return {
      'ratings': [
        for (final rating in ratings.entries)
          {'id': rating.key, 'rt': rating.value},
      ],
    };
  }
}
