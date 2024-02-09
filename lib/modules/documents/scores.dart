class Scores {
  final int? thumbs;
  final int? popularity;
  final int? metacritic;
  final int? espyScore;

  final String? espyTier;

  const Scores({
    this.thumbs,
    this.popularity,
    this.metacritic,
    this.espyScore,
    this.espyTier,
  });

  Scores.fromJson(Map<String, dynamic> json)
      : this(
          thumbs: json['thumbs'],
          popularity: json['popularity'],
          metacritic: json['metacritic'],
          espyScore: json['espy_score'],
          espyTier: json['espy_tier'],
        );

  Map<String, dynamic> toJson() {
    return {
      if (thumbs != null) 'thumbs': thumbs,
      if (popularity != null) 'popularity': popularity,
      if (metacritic != null) 'metacritic': metacritic,
      if (espyScore != null) 'espy_score': espyScore,
      if (espyTier != null) 'espy_tier': espyTier,
    };
  }

  bool hasDiff(Scores other) {
    return thumbs != other.thumbs ||
        popularity != other.popularity ||
        metacritic != other.metacritic ||
        espyScore != other.espyScore ||
        espyTier != other.espyTier;
  }
}
