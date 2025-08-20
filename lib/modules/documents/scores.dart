class Scores {
  final int? thumbs;
  final int? popularity;
  final int? hype;

  final int? metacritic;
  final String? metacriticSource;

  final int? espyScore;
  final int? prominence;

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
    this.prominence,
  });

  Scores.fromJson(Map<String, dynamic> json)
      : this(
          thumbs: json['thumbs'],
          popularity: json['popularity'],
          hype: json['hype'],
          metacritic: json['metacritic'],
          metacriticSource: json['metacritic_source'],
          espyScore: json['espy_score'],
          prominence: json['prominence'],
        );

  Map<String, dynamic> toJson() {
    return {
      if (thumbs != null) 'thumbs': thumbs,
      if (popularity != null) 'popularity': popularity,
      if (hype != null) 'hype': hype,
      if (metacritic != null) 'metacritic': metacritic,
      if (metacriticSource != null) 'metacritic_source': metacriticSource,
      if (espyScore != null) 'espy_score': espyScore,
      if (prominence != null) 'prominence': prominence,
    };
  }

  bool hasDiff(Scores other) {
    return thumbs != other.thumbs ||
        popularity != other.popularity ||
        hype != other.hype ||
        metacritic != other.metacritic ||
        espyScore != other.espyScore ||
        prominence != other.prominence;
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
