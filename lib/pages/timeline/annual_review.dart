import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/timeline_model.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AnnualReview extends StatelessWidget {
  const AnnualReview({super.key, required this.year});

  final String year;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppConfigModel.isMobile(context);
    final today = DateFormat('d MMM').format(DateTime.now());

    return FutureBuilder(
      future: context.watch<TimelineModel>().gamesIn(year),
      builder: (BuildContext context,
          AsyncSnapshot<List<(DateTime, GameDigest)>> snapshot) {
        return snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData
            ? timeline(today, snapshot.data!, isMobile)
            : Container();
      },
    );
  }

  Widget timeline(
      String today, List<(DateTime, GameDigest)> games, bool isMobile) {
    final digests = games.map((tupl) => tupl.$2).toList();

    final popular = digests
        .where((digest) =>
            digest.scores.popularity != null &&
            digest.scores.popularity! >= 100000)
        .toList();
    popular.sort((left, right) =>
        -left.scores.popularity!.compareTo(right.scores.popularity!));

    final highlights = digests
        .where((digest) =>
            digest.scores.metacritic != null && digest.scores.metacritic! >= 80)
        .toList();
    highlights.sort((left, right) =>
        -left.scores.metacritic!.compareTo(right.scores.metacritic!));

    final releases = digests
        .where((digest) =>
            digest.scores.metacritic != null && digest.scores.metacritic! < 80)
        .toList();
    releases.sort((left, right) =>
        -left.scores.metacritic!.compareTo(right.scores.metacritic!));

    final rest =
        digests.where((digest) => digest.scores.metacritic == null).toList();
    rest.sort((left, right) =>
        -(left.scores.popularity ?? 0).compareTo(right.scores.popularity ?? 0));

    final groups = [
      if (popular.isNotEmpty) ('Most popular', popular),
      ('Release Highlights', highlights),
      ('Releases', releases),
      ('Rest', rest),
    ];

    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        for (final (label, digests) in groups)
          TileShelve(
            title: '$label (${digests.length})',
            color: Colors.grey,
            entries:
                digests.map((digest) => LibraryEntry.fromGameDigest(digest)),
          ),
      ],
    );
  }
}
