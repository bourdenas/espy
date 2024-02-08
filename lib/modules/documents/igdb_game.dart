class IgdbGame {
  final int id;
  final String name;

  final String summary;
  final String storyline;
  final int releaseDate;
  final double rating;
  final String url;

  const IgdbGame({
    required this.id,
    required this.name,
    this.summary = '',
    this.storyline = '',
    this.releaseDate = 0,
    this.rating = 0.0,
    this.url = '',
  });

  IgdbGame.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          name: json['name']!,
          summary: json['summary'] ?? '',
          storyline: json['storyline'] ?? '',
          releaseDate: json['first_release_date'] ?? 0,
          rating: json['aggregated_rating'] ?? 0,
          url: json['url'] ?? '',
        );

  Map<String, dynamic> toJson() => {};
}
