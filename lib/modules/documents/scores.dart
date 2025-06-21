class Scores {
  final int? thumbs;
  final int? popularity;
  final int? hype;
  final int? metacritic;
  final String? metacriticSource;
  final int? espyScore;

  final String? espyTier;

  // Prominence is a single number that mixes other metrics to determine
  // relative ranking among titles.
  int get prominence {
    int pop = popularity ?? 0;
    if (metacritic == null) {
      pop ~/= 2;
    }

    final score = switch (espyScore) {
      int x when x >= 95 => 300000 + (x - 90) * 10000,
      int x when x >= 90 => 200000 + (x - 90) * 10000,
      int x when x >= 80 => 100000 + (x - 80) * 10000,
      int x when x >= 0 => x * 1000,
      _ => 0,
    };
    return score + pop;
  }

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
    this.metacriticSource,
    this.espyScore,
    this.espyTier,
  });

  Scores.fromJson(Map<String, dynamic> json)
      : this(
          thumbs: json['thumbs'],
          popularity: json['popularity'],
          hype: json['hype'],
          metacritic: json['metacritic'],
          metacriticSource: json['metacritic_source'],
          espyScore: json['espy_score'],
          espyTier: json['espy_tier'],
        );

  Map<String, dynamic> toJson() {
    return {
      if (thumbs != null) 'thumbs': thumbs,
      if (popularity != null) 'popularity': popularity,
      if (hype != null) 'hype': hype,
      if (metacritic != null) 'metacritic': metacritic,
      if (metacriticSource != null) 'metacritic_source': metacriticSource,
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
