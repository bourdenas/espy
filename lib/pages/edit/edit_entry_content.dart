import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/edit/storefront_view.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/pages/edit/edit_manual_tags.dart';
import 'package:espy/pages/edit/edit_genre_tags.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class EditEntryContent extends StatelessWidget {
  const EditEntryContent({
    super.key,
    required this.libraryEntry,
    this.gameEntry,
    this.gameId,
  });

  final LibraryEntry libraryEntry;
  final GameEntry? gameEntry;
  final int? gameId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          gameEntry == null ? _getGameEntry(gameId!) : Future.value(gameEntry!),
      builder: (BuildContext context, AsyncSnapshot<GameEntry?> snapshot) {
        final defaultContext = _EditEntryView(libraryEntry: libraryEntry);

        if (snapshot.hasError) {
          return defaultContext;
        }

        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasData) {
          return defaultContext;
        }

        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return _EditEntryView(
            libraryEntry: libraryEntry,
            gameEntry: snapshot.data,
          );
        }

        return defaultContext;
      },
    );
  }
}

Future<GameEntry> _getGameEntry(int gameId) async {
  final snapshot =
      await FirebaseFirestore.instance.collection('games').doc('$gameId').get();
  return GameEntry.fromJson(snapshot.data()!);
}

class _EditEntryView extends StatelessWidget {
  const _EditEntryView({
    required this.libraryEntry,
    this.gameEntry,
  });

  final LibraryEntry libraryEntry;
  final GameEntry? gameEntry;

  @override
  Widget build(BuildContext context) {
    List<String> keywords = gameEntry?.keywords ?? <String>[];
    List<String> steamTags = gameEntry?.steamData?.userTags ?? <String>[];
    final genres = Set.from((gameEntry?.igdbGenres ?? <String>[]) +
        (gameEntry?.steamData?.genres.map((e) => e.description).toList() ??
            <String>[]));

    return ListView(
      shrinkWrap: true,
      children: [
        const SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              CircleAvatar(
                foregroundImage: CachedNetworkImageProvider(
                  '${Urls.imageProvider}/t_thumb/${libraryEntry.cover}.jpg',
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Text(
                  libraryEntry.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        Card(
          child: ExpandableNotifier(
            initialExpanded: true,
            child: ExpandablePanel(
              header: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Game Genres'),
              ),
              collapsed: Container(),
              expanded: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4.0),
                  EditGenreTags(libraryEntry, keywords + steamTags),
                  const SizedBox(height: 8.0),
                ],
              ),
            ),
          ),
        ),
        Card(
          child: ExpandableNotifier(
            initialExpanded: true,
            child: ExpandablePanel(
              header: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Game Tags'),
              ),
              collapsed: Container(),
              expanded: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (genres.isNotEmpty) ...[
                    const SizedBox(height: 4.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Genres: ${genres.join(", ")}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                  ],
                  if (steamTags.isNotEmpty) ...[
                    const SizedBox(height: 4.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Steam: ${steamTags.join(", ")}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                  ],
                  if (keywords.isNotEmpty) ...[
                    const SizedBox(height: 4.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'IGDB: ${keywords.join(", ")}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8.0),
                  EditManualTags(libraryEntry, keywords + steamTags),
                  const SizedBox(height: 16.0),
                  const SizedBox(height: 8.0),
                ],
              ),
            ),
          ),
        ),
        if (libraryEntry.storeEntries.isNotEmpty)
          Card(
            child: ExpandableNotifier(
              initialExpanded: true,
              child: ExpandablePanel(
                header: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Storefronts'),
                ),
                collapsed: Container(),
                expanded: StorefrontView(libraryEntry),
              ),
            ),
          ),
      ],
    );
  }
}
