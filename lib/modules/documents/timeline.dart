import 'package:espy/modules/documents/game_digest.dart';

class Timeline {
  final List<ReleaseEvent> releases;

  const Timeline({
    this.releases = const [],
  });

  Timeline.fromJson(Map<String, dynamic> json)
      : this(releases: [
          for (final event in json['releases'] ?? [])
            ReleaseEvent.fromJson(event),
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
  final List<GameDigest> earlyAccess;
  final List<GameDigest> debug;

  const AnnualReviewDoc({
    this.releases = const [],
    this.indies = const [],
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
