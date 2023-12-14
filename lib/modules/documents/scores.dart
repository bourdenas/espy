class Scores {
  final int? tier;
  final int? thumbs;
  final int? popularity;
  final int? metacritic;

  final String? espyTier;
  final String? thumbsTier;
  final String? popularityTier;
  final String? criticsTier;

  const Scores({
    this.tier,
    this.thumbs,
    this.popularity,
    this.metacritic,
    this.espyTier,
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
          espyTier: json['espy_tier'],
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
      if (espyTier != null) 'espy_tier': espyTier,
      if (thumbsTier != null) 'thumbs_tier': thumbsTier,
      if (popularityTier != null) 'pop_tier': popularityTier,
      if (criticsTier != null) 'critics_tier': criticsTier,
    };
  }
}
