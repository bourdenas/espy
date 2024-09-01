class Scores {
  final int? thumbs;
  final int? popularity;
  final int? hype;
  final int? metacritic;
  final int? espyScore;

  final String? espyTier;

  String get title => switch (metacritic) {
        int x when x >= 90 => 'Excellent',
        int x when x >= 80 => 'Great',
        int x when x >= 70 => 'Good',
        int x when x >= 60 => 'Mixed',
        int() => 'Bad',
        null => 'Unknown',
      };

  const Scores({
    this.thumbs,
    this.popularity,
    this.hype,
    this.metacritic,
    this.espyScore,
    this.espyTier,
  });

  Scores.fromJson(Map<String, dynamic> json)
      : this(
          thumbs: json['thumbs'],
          popularity: json['popularity'],
          hype: json['hype'],
          metacritic: json['metacritic'],
          espyScore: json['espy_score'],
          espyTier: json['espy_tier'],
        );

  Map<String, dynamic> toJson() {
    return {
      if (thumbs != null) 'thumbs': thumbs,
      if (popularity != null) 'popularity': popularity,
      if (hype != null) 'hype': hype,
      if (metacritic != null) 'metacritic': metacritic,
      if (espyScore != null) 'espy_score': espyScore,
      if (espyTier != null) 'espy_tier': espyTier,
    };
  }

  bool hasDiff(Scores other) {
    return thumbs != other.thumbs ||
        popularity != other.popularity ||
        hype != other.hype ||
        metacritic != other.metacritic ||
        espyScore != other.espyScore ||
        espyTier != other.espyTier;
  }
}

const scoreTitles = [
  'Excellent',
  'Great',
  'Good',
  'Mixed',
  'Bad',
  'Unknown',
];
