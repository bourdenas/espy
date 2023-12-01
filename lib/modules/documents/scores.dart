class Scores {
  final int? tier;
  final int? thumbs;
  final int? popularity;
  final int? metacritic;

  const Scores({
    this.tier,
    this.thumbs,
    this.popularity,
    this.metacritic,
  });

  Scores.fromJson(Map<String, dynamic> json)
      : this(
          tier: json['tier'],
          thumbs: json['thumbs'],
          popularity: json['popularity'],
          metacritic: json['metacritic'],
        );

  Map<String, dynamic> toJson() {
    return {
      if (tier != null) 'tier': tier,
      if (thumbs != null) 'thumbs': thumbs,
      if (popularity != null) 'popularity': popularity,
      if (metacritic != null) 'metacritic': metacritic,
    };
  }
}
