import 'dart:math';

import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/igdb_collection.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/backend_api.dart';
import 'package:espy/pages/calendar/calendar_view_year.dart';
import 'package:espy/pages/library/library_stats.dart';
import 'package:espy/widgets/shelve.dart';
import 'package:flutter/material.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: BackendApi.collectionFetch(name),
      builder: (BuildContext context, AsyncSnapshot<IgdbCollection?> snapshot) {
        return snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData
            ? CollectionContent(snapshot.data!)
            : Container();
      },
    );
  }
}

class CollectionContent extends StatelessWidget {
  const CollectionContent(this.collection, {super.key});

  final IgdbCollection collection;

  @override
  Widget build(BuildContext context) {
    final minDateDeveloped = collection.games.isEmpty
        ? DateTime(1970)
        : DateTime.fromMillisecondsSinceEpoch(collection.games
                .map((digest) => digest.releaseDate)
                .where((date) => date > 0)
                .reduce(min) *
            1000);
    final maxDateDeveloped = collection.games.isEmpty
        ? DateTime(1970)
        : DateTime.fromMillisecondsSinceEpoch(collection.games
                .map((digest) => digest.releaseDate)
                .where((date) => date > 0)
                .reduce(max) *
            1000);

    final games = groupDigestsBy(
      collection.games,
      byKey: (digest) => '${digest.releaseYear}',
      sortBy: (l, r) => l.releaseDate.compareTo(r.releaseDate),
    );

    return Column(
      children: [
        Shelve(
          title: 'Drill-down',
          expansion: LibraryStats(collection.games
              .map((digest) => LibraryEntry.fromGameDigest(digest))),
          color: Colors.amber,
        ),
        Expanded(
          child: CalendarViewYear(
            startYear: maxDateDeveloped.year,
            endYear: minDateDeveloped.year,
            gamesByYear: games,
          ),
        ),
      ],
    );
  }
}
