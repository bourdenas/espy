import 'package:espy/modules/documents/game_digest.dart';

class Timeline {
  final List<GameDigest> upcoming;
  final List<GameDigest> recent;

  const Timeline({
    this.upcoming = const [],
    this.recent = const [],
  });

  Timeline.fromJson(Map<String, dynamic> json)
      : this(
          upcoming: [
            for (final entry in json['upcoming'] ?? [])
              GameDigest.fromJson(entry),
          ],
          recent: [
            for (final entry in json['recent'] ?? [])
              GameDigest.fromJson(entry),
          ],
        );

  Map<String, dynamic> toJson() {
    return {
      if (upcoming.isNotEmpty)
        'upcoming': [
          for (final entry in upcoming) entry.toJson(),
        ],
      if (recent.isNotEmpty)
        'recent': [
          for (final entry in recent) entry.toJson(),
        ],
    };
  }
}
