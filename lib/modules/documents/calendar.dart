import 'package:espy/modules/documents/game_digest.dart';

class Calendar {
  final List<ReleaseEvent> years;

  const Calendar({
    this.years = const [],
  });

  Calendar.fromJson(Map<String, dynamic> json)
      : this(years: [
          for (final event in json['years'] ?? []) ReleaseEvent.fromJson(event),
        ]);

  Map<String, dynamic> toJson() {
    return {};
  }
}

class ReleaseEvent {
  final String label;
  final String year;
  final List<GameDigest> games;

  const ReleaseEvent({
    this.label = '',
    this.year = '',
    this.games = const [],
  });

  ReleaseEvent.fromJson(Map<String, dynamic> json)
      : this(
          label: json['label'],
          year: json['year'],
          games: [
            for (final game in json['games'] ?? []) GameDigest.fromJson(game),
          ],
        );

  Map<String, dynamic> toJson() {
    return {};
  }
}

class AnnualReviewDoc {
  final List<GameDigest> releases;
  final List<GameDigest> indies;
  final List<GameDigest> remasters;
  final List<GameDigest> expansions;
  final List<GameDigest> casual;
  final List<GameDigest> earlyAccess;
  final List<GameDigest> debug;

  const AnnualReviewDoc({
    this.releases = const [],
    this.indies = const [],
    this.remasters = const [],
    this.expansions = const [],
    this.casual = const [],
    this.earlyAccess = const [],
    this.debug = const [],
  });

  AnnualReviewDoc.fromJson(Map<String, dynamic> json)
      : this(
          releases: [
            for (final event in json['releases'] ?? [])
              GameDigest.fromJson(event),
          ],
          indies: [
            for (final event in json['indies'] ?? [])
              GameDigest.fromJson(event),
          ],
          remasters: [
            for (final event in json['remasters'] ?? [])
              GameDigest.fromJson(event),
          ],
          expansions: [
            for (final event in json['expansions'] ?? [])
              GameDigest.fromJson(event),
          ],
          casual: [
            for (final event in json['casual'] ?? [])
              GameDigest.fromJson(event),
          ],
          earlyAccess: [
            for (final event in json['early_access'] ?? [])
              GameDigest.fromJson(event),
          ],
          debug: [
            for (final event in json['debug'] ?? []) GameDigest.fromJson(event),
          ],
        );

  Map<String, dynamic> toJson() {
    return {};
  }
}
