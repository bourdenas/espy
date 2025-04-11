import 'dart:math';

import 'package:espy/modules/documents/igdb_collection.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/models/backend_api.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/calendar/calendar_view_year.dart';
import 'package:espy/widgets/stats/filter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: BackendApi.collectionFetch(name),
      builder: (BuildContext context, AsyncSnapshot<IgdbCollection?> snapshot) {
        IgdbCollection? collection =
            (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData)
                ? snapshot.data
                : null;

        return Scaffold(
          appBar: AppBar(
            leading: badges.Badge(
              badgeContent: Text(
                '${collection?.games.length ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              badgeStyle: badges.BadgeStyle(
                shape: badges.BadgeShape.circle,
                badgeColor: Theme.of(context).colorScheme.primaryContainer,
                padding: const EdgeInsets.all(8),
              ),
              position: badges.BadgePosition.center(),
              child: Container(),
            ),
            title: Text(name),
          ),
          body:
              collection != null ? CollectionContent(collection) : Container(),
        );
      },
    );
  }
}

class CollectionContent extends StatelessWidget {
  const CollectionContent(this.collection, {super.key});

  final IgdbCollection collection;

  @override
  Widget build(BuildContext context) {
    final shownGames = context.watch<FilterModel>().process(collection.games);

    final (startYear, endYear) = (
      collection.games.map((digest) => digest.releaseYear).reduce(max),
      collection.games.map((digest) => digest.releaseYear).reduce(min),
    );

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: CalendarViewYear(
                shownGames,
                startYear: startYear,
                endYear: endYear,
              ),
            ),
            // Add some space for the bottom sheet.
            SizedBox(height: 52),
          ],
        ),
        FilterBottomSheet(collection.games
            .map((digest) => LibraryEntry.fromGameDigest(digest))),
      ],
    );
  }
}
