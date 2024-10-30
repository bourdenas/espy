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
            for (final digest in json['today_releases'] ?? [])
              GameDigest.fromJson(digest),
          ],
          upcomingReleases: [
            for (final digest in json['upcoming_releases'] ?? [])
              GameDigest.fromJson(digest),
          ],
          recentReleases: [
            for (final digest in json['recent_releases'] ?? [])
              GameDigest.fromJson(digest),
          ],
          hyped: [
            for (final digest in json['hyped'] ?? [])
              GameDigest.fromJson(digest),
          ],
        );

  Map<String, dynamic> toJson() {
    return {};
  }
}
