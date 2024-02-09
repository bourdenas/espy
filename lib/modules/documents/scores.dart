class Scores {
  final int? tier;
  final int? thumbs;
  final int? popularity;
  final int? metacritic;
  final int? espyScore;

  final String espyTier;
  final String? thumbsTier;
  final String? popularityTier;
  final String? criticsTier;

  const Scores({
    this.tier,
    this.thumbs,
    this.popularity,
    this.metacritic,
    this.espyScore,
    this.espyTier = 'Unknown',
    this.thumbsTier,
    this.popularityTier,
    this.criticsTier,
  });

  Scores.fromJson(Map<String, dynamic> json)
      : this(
          tier: json['tier'],
          thumbs: json['thumbs'],
          popularity: json['popularity'],
          metacritic: json['metacritic'],
          espyScore: json['espy_score'],
          espyTier: json['espy_tier'] ?? 'Unknown',
          thumbsTier: json['thumbs_tier'],
          popularityTier: json['pop_tier'],
          criticsTier: json['critics_tier'],
        );

  Map<String, dynamic> toJson() {
    return {
      if (tier != null) 'tier': tier,
      if (thumbs != null) 'thumbs': thumbs,
      if (popularity != null) 'popularity': popularity,
      if (metacritic != null) 'metacritic': metacritic,
      if (espyScore != null) 'espy_score': espyScore,
      if (espyTier != 'Unknown') 'espy_tier': espyTier,
      if (thumbsTier != null) 'thumbs_tier': thumbsTier,
      if (popularityTier != null) 'pop_tier': popularityTier,
      if (criticsTier != null) 'critics_tier': criticsTier,
    };
  }

  bool hasDiff(Scores other) {
    return tier != other.tier ||
        thumbs != other.thumbs ||
        popularity != other.popularity ||
        metacritic != other.metacritic ||
        espyScore != other.espyScore ||
        espyTier != other.espyTier ||
        thumbsTier != other.thumbsTier ||
        popularityTier != other.popularityTier ||
        criticsTier != other.criticsTier;
  }
}
