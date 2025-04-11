import 'dart:math';

import 'package:espy/modules/documents/igdb_collection.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/backend_api.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/calendar/calendar_view_year.dart';
import 'package:espy/widgets/stats/refinements_bottom_sheet.dart';
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
    final refinement = context.watch<RefinementModel>().refinement;
    final refinedEntries =
        collection.games.where((e) => refinement.pass(e)).toList();

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
                refinedEntries,
                startYear: startYear,
                endYear: endYear,
              ),
            ),
            // Add some space for the bottom sheet.
            SizedBox(height: 52),
          ],
        ),
        RefinementsBottomSheet(collection.games
            .map((digest) => LibraryEntry.fromGameDigest(digest))),
      ],
    );
  }
}
