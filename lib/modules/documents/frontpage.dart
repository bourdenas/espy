import 'package:espy/modules/documents/game_digest.dart';

class Frontpage {
  final List<GameDigest> upcoming;
  final List<GameDigest> mostAnticipated;
  final List<GameDigest> recent;
  final List<GameDigest> popular;
  final List<GameDigest> criticallyAcclaimed;

  const Frontpage({
    this.upcoming = const [],
    this.mostAnticipated = const [],
    this.recent = const [],
    this.popular = const [],
    this.criticallyAcclaimed = const [],
  });

  Frontpage.fromJson(Map<String, dynamic> json)
      : this(
          upcoming: [
            for (final entry in json['upcoming'] ?? [])
              GameDigest.fromJson(entry),
          ],
          mostAnticipated: [
            for (final entry in json['most_anticipated'] ?? [])
              GameDigest.fromJson(entry),
          ],
          recent: [
            for (final entry in json['recent'] ?? [])
              GameDigest.fromJson(entry),
          ],
          popular: [
            for (final entry in json['popular'] ?? [])
              GameDigest.fromJson(entry),
          ],
          criticallyAcclaimed: [
            for (final entry in json['critically_acclaimed'] ?? [])
              GameDigest.fromJson(entry),
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      if (upcoming.isNotEmpty)
        'upcoming': [
          for (final entry in upcoming) entry.toJson(),
        ],
      if (mostAnticipated.isNotEmpty)
        'most_anticipated': [
          for (final entry in mostAnticipated) entry.toJson(),
        ],
      if (recent.isNotEmpty)
        'recent': [
          for (final entry in recent) entry.toJson(),
        ],
      if (popular.isNotEmpty)
        'popular': [
          for (final entry in popular) entry.toJson(),
        ],
      if (criticallyAcclaimed.isNotEmpty)
        'critically_acclaimed': [
          for (final entry in criticallyAcclaimed) entry.toJson(),
        ],
    };
  }
}
