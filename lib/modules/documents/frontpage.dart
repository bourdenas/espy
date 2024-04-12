import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/timeline.dart';

class Frontpage {
  final List<ReleaseEvent> releases;
  final List<GameDigest> today;
  final List<GameDigest> recent;
  final List<GameDigest> upcoming;
  final List<GameDigest> newUpdated;
  final List<GameDigest> hyped;

  const Frontpage({
    this.releases = const [],
    this.today = const [],
    this.recent = const [],
    this.upcoming = const [],
    this.newUpdated = const [],
    this.hyped = const [],
  });

  Frontpage.fromJson(Map<String, dynamic> json)
      : this(
          releases: [
            for (final event in json['releases'] ?? [])
              ReleaseEvent.fromJson(event),
          ],
          today: [
            for (final event in json['today'] ?? []) GameDigest.fromJson(event),
          ],
          recent: [
            for (final event in json['recent'] ?? [])
              GameDigest.fromJson(event),
          ],
          upcoming: [
            for (final event in json['upcoming'] ?? [])
              GameDigest.fromJson(event),
          ],
          newUpdated: [
            for (final event in json['new'] ?? []) GameDigest.fromJson(event),
          ],
          hyped: [
            for (final event in json['hyped'] ?? []) GameDigest.fromJson(event),
          ],
        );

  Map<String, dynamic> toJson() {
    return {};
  }
}
