import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/timeline.dart';

class Frontpage {
  final List<ReleaseEvent> timeline;
  final List<GameDigest> todayReleases;
  final List<GameDigest> upcomingReleases;
  final List<GameDigest> recentReleases;
  final List<GameDigest> hyped;

  const Frontpage({
    this.timeline = const [],
    this.todayReleases = const [],
    this.recentReleases = const [],
    this.upcomingReleases = const [],
    this.hyped = const [],
  });

  Frontpage.fromJson(Map<String, dynamic> json)
      : this(
          timeline: [
            for (final event in json['timeline'] ?? [])
              ReleaseEvent.fromJson(event),
          ],
          todayReleases: [
            for (final event in json['today_releases'] ?? [])
              GameDigest.fromJson(event),
          ],
          upcomingReleases: [
            for (final event in json['upcoming_releases'] ?? [])
              GameDigest.fromJson(event),
          ],
          recentReleases: [
            for (final event in json['recent_releases'] ?? [])
              GameDigest.fromJson(event),
          ],
          hyped: [
            for (final event in json['hyped'] ?? []) GameDigest.fromJson(event),
          ],
        );

  Map<String, dynamic> toJson() {
    return {};
  }
}
