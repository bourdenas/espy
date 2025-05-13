import 'dart:math';

import 'package:espy/modules/documents/igdb_collection.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/backend_api.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/calendar/calendar_view_year.dart';
import 'package:espy/widgets/stats/filter_side_pane.dart';
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

        return Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      leading: badges.Badge(
                        badgeContent: Text(
                          '${collection?.games.length ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        badgeStyle: badges.BadgeStyle(
                          shape: badges.BadgeShape.circle,
                          badgeColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          padding: const EdgeInsets.all(8),
                        ),
                        position: badges.BadgePosition.center(),
                        child: Container(),
                      ),
                      title: Text(name),
                    ),
                    body: collection != null
                        ? CollectionContent(collection)
                        : Container(),
                  ),
                ),
                // Add some space for the bottom sheet.
                SizedBox(
                  width: context.watch<AppConfigModel>().showBottomSheet
                      ? 500
                      : 40,
                ),
              ],
            ),
            FilterSidePane(
              collection?.games
                      .map((digest) => LibraryEntry.fromGameDigest(digest)) ??
                  [],
            ),
          ],
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
      collection.games
          .map((digest) => digest.releaseYear)
          .where((year) => year > 1970)
          .reduce(min),
    );

    return CalendarViewYear(
      shownGames,
      startYear: startYear,
      endYear: endYear,
    );
  }
}
