class IgdbGame {
  final int id;
  final String name;

  final String summary;
  final String storyline;
  final int releaseDate;
  final double rating;

  const IgdbGame({
    required this.id,
    required this.name,
    this.summary = '',
    this.storyline = '',
    this.releaseDate = 0,
    this.rating = 0.0,
  });

  IgdbGame.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          name: json['name']!,
          summary: json['summary'] ?? '',
          storyline: json['storyline'] ?? '',
          releaseDate: json['first_release_date'] ?? 0,
          rating: json['aggregated_rating'] ?? 0,
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (summary.isNotEmpty) 'summary': summary,
      if (storyline.isNotEmpty) 'storyline': storyline,
      if (releaseDate > 0) 'first_release_date': releaseDate,
      if (rating > 0.0) 'aggregated_rating': rating,
    };
  }
}
