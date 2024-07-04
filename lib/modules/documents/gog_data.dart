class GogData {
  final String? releaseDate;
  final String? logo;
  final String? description;

  final int? criticScore;

  final List<String> genres;
  final List<String> tags;

  const GogData({
    this.releaseDate,
    this.logo,
    this.description,
    this.criticScore,
    this.genres = const [],
    this.tags = const [],
  });

  GogData.fromJson(Map<String, dynamic> json)
      : this(
          releaseDate: json['release_date'],
          logo: json['logo'],
          description: json['description'],
          criticScore: json['critic_score'],
          genres: [
            for (final genre in json['genres'] ?? []) genre,
          ],
          tags: [
            for (final tag in json['tags'] ?? []) tag,
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      if (releaseDate != null) 'release_date': releaseDate,
      if (logo != null) 'logo': logo,
      if (description != null) 'description': description,
      if (criticScore != null) 'critic_score': criticScore,
      if (genres.isNotEmpty) 'genres': genres,
      if (tags.isNotEmpty) 'tags': tags,
    };
  }
}
