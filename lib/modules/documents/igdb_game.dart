class IgdbGame {
  final int id;
  final String name;

  final String summary;
  final String url;

  final double rating;
  final int follows;
  final int hypes;

  const IgdbGame({
    required this.id,
    required this.name,
    this.summary = '',
    this.url = '',
    this.rating = 0.0,
    this.follows = 0,
    this.hypes = 0,
  });

  IgdbGame.fromJson(Map<String, dynamic> json)
      : this(
          id: json['id']!,
          name: json['name']!,
          summary: json['summary'] ?? '',
          url: json['url'] ?? '',
          rating: json['aggregated_rating'] ?? 0,
          follows: json['follows'] ?? 0,
          hypes: json['hypes'] ?? 0,
        );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (rating > 0) 'aggreated_rating': rating,
        if (follows > 0) 'follows': follows,
        if (hypes > 0) 'hypes': hypes,
      };
}
