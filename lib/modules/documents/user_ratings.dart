class UserRatings {
  Map<int, int> ratings;

  UserRatings({
    this.ratings = const {},
  });

  UserRatings.fromJson(Map<String, dynamic> json)
      : this(
          ratings: {}..addEntries([
              for (final genre in json['ratings'] ?? [])
                MapEntry(genre[0], genre[1])
            ]),
        );

  Map<String, dynamic> toJson() {
    return {
      'ratings': [
        for (final rating in ratings.entries) [rating.key, rating.value],
      ],
    };
  }
}
