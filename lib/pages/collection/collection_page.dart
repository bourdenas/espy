import 'package:espy/modules/documents/game_digest.dart';
import 'package:espy/modules/documents/igdb_collection.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:badges/badges.dart' as badges;
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/backend_api.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/calendar/calendar_view_year.dart';
import 'package:espy/pages/timeline/timeline_view.dart';
import 'package:espy/widgets/stats/filter_side_pane.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key, required this.name});

  final String name;

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  late Future<IgdbCollection?> _collection;

  @override
  void initState() {
    super.initState();
    _collection = BackendApi.collectionFetch(widget.name);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _collection,
      builder: (BuildContext context, AsyncSnapshot<IgdbCollection?> snapshot) {
        IgdbCollection? collection =
            (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData)
                ? snapshot.data
                : null;

        return collection != null ? CollectionContent(collection) : loading();
      },
    );
  }

  Widget loading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Retrieving collection...'),
          SizedBox(height: 16),
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}

class CollectionContent extends StatelessWidget {
  const CollectionContent(this.collection, {super.key});

  final IgdbCollection collection;

  @override
  Widget build(BuildContext context) {
    final shownGames = context.watch<FilterModel>().process(collection.games);

    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: Scaffold(
                appBar: appbar(context),
                body: content(context, shownGames),
              ),
            ),
            // Add some space for the side pane.
            SizedBox(
              width: context.watch<AppConfigModel>().showBottomSheet ? 500 : 40,
            ),
          ],
        ),
        FilterSidePane(
          collection.games.map((digest) => LibraryEntry.fromGameDigest(digest)),
        ),
      ],
    );
  }

  Widget content(BuildContext context, Iterable<GameDigest> shownGames) {
    return switch (context.watch<AppConfigModel>().libraryLayout.value) {
      LibraryLayout.grid => CalendarViewYear(shownGames),
      LibraryLayout.list => TimelineView(
          shownGames.map((digest) => LibraryEntry.fromGameDigest(digest))),
    };
  }

  AppBar appbar(BuildContext context) {
    return AppBar(
      leading: badges.Badge(
        badgeContent: Text(
          '${collection.games.length}',
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
      title: Text(collection.name),
    );
  }
}
