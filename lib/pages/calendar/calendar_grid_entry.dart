import 'package:espy/modules/documents/game_digest.dart';

class CalendarGridEntry {
  static CalendarGridEntry empty = CalendarGridEntry(null, [], onClick: (_) {});

  const CalendarGridEntry(
    this.label,
    this.digests, {
    required this.onClick,
    this.coverExtractor,
  });

  final String? label;
  final List<GameDigest> digests;
  final void Function(CalendarGridEntry) onClick;

  final List<GameDigest> Function(Iterable<GameDigest> games)? coverExtractor;

  List<GameDigest> getCovers() {
    final mainGames = digests.where((e) => e.isMain);
    final covers = coverExtractor != null
        ? coverExtractor!(mainGames)
        : _defaultExtractor(mainGames);

    return covers.isNotEmpty
        ? covers
        : coverExtractor != null
            ? coverExtractor!(digests)
            : _defaultExtractor(digests);
  }

  List<GameDigest> _defaultExtractor(Iterable<GameDigest> games) {
    final mostPopular = games
        .where((digest) => (digest.scores.popularity ?? 0) > 0)
        .toList()
      ..sort((a, b) => b.scores.popularity!.compareTo(a.scores.popularity!));
    if (mostPopular.isNotEmpty) {
      if (mostPopular.length > 1 &&
          mostPopular[0].scores.popularity! >=
              2 * mostPopular[1].scores.popularity!) {
        return [mostPopular[0]];
      } else {
        return mostPopular.take(4).toList();
      }
    }

    final scored = games
        .where((digest) => (digest.scores.espyScore ?? 0) > 0)
        .toList()
      ..sort((a, b) => b.scores.espyScore!.compareTo(a.scores.espyScore!));
    if (scored.isNotEmpty) {
      final highlyScored =
          scored.where((digest) => digest.scores.espyScore! >= 80).length;
      if (highlyScored > 0 && highlyScored < 3) {
        return [scored[0]];
      } else {
        return scored.take(4).toList();
      }
    }

    final hyped = games
        .where((digest) => (digest.scores.hype ?? 0) > 0)
        .toList()
      ..sort((a, b) => b.scores.hype!.compareTo(a.scores.hype!));
    if (hyped.isNotEmpty) {
      if (hyped.length > 1 &&
          hyped[0].scores.hype! >= 2 * hyped[1].scores.hype!) {
        return [hyped[0]];
      } else {
        return hyped.take(4).toList();
      }
    }

    return games.toList();
  }
}
