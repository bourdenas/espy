// import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/widgets/details/game_tags.dart';
import 'package:espy/widgets/dialogs/game_entry_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameDetails extends StatelessWidget {
  final LibraryEntry entry;

  GameDetails(
    this.entry, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final layout = context.read<AppConfigModel>().isMobile
        ? _Layout.singleColumn
        : _Layout.twoColumns;

    return Scaffold(
      body: GameEntryView(
        libraryEntry: entry,
        layout: layout,
      ),
    );
  }
}

class GameEntryView extends StatelessWidget {
  const GameEntryView({
    Key? key,
    required this.libraryEntry,
    required this.layout,
  }) : super(key: key);

  final LibraryEntry libraryEntry;
  final _Layout layout;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('games')
          .doc('${libraryEntry.id}')
          .get(),
      builder: (context, snapshot) {
        List<Widget> tailSlivers = [];

        if (snapshot.hasError) {
          tailSlivers.add(SliverGrid.count(
            crossAxisCount: 1,
            children: [
              Text("Something went wrong: ${snapshot.error}"),
            ],
          ));
        } else if (!snapshot.hasData) {
          tailSlivers.add(SliverGrid.count(
            crossAxisCount: 1,
            children: [
              Text("Document does not exist"),
            ],
          ));
        } else if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          // Cannot believe people are using json by choice! WTF is going on here?
          final skata = (snapshot.data! as DocumentSnapshot).data()
              as Map<String, dynamic>;
          final gameEntry = GameEntry.fromJson(skata);

          tailSlivers = [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Column(
                    children: [
                      if (layout == _Layout.singleColumn) ...[
                        Padding(padding: const EdgeInsets.all(16)),
                        _GameTitle(libraryEntry),
                      ],
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: SelectableText(gameEntry.summary),
                      )
                    ],
                  );
                },
                childCount: 1,
              ),
            ),
            _ScreenshotsSliver(gameEntry, layout),
          ];
        } else {
          tailSlivers.add(SliverGrid.count(
            crossAxisCount: 1,
            children: [
              Center(child: CircularProgressIndicator()),
            ],
          ));
        }

        return CustomScrollView(
          slivers: [
            _HeaderSliver(libraryEntry, layout),
            ...tailSlivers,
          ],
        );
      },
    );
  }
}

enum _Layout {
  singleColumn,
  twoColumns,
}

class _HeaderSliver extends StatelessWidget {
  final LibraryEntry libraryEntry;
  final _Layout layout;

  const _HeaderSliver(this.libraryEntry, this.layout);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 320.0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(children: [
          // Material(
          //   elevation: 2,
          //   shape:
          //       RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          //   clipBehavior: Clip.antiAlias,
          //   child: BackdropFilter(
          //     filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          //     child: Image.network(
          //       'https://images.igdb.com/igdb/image/upload/t_720p/${entry.game.artworks[0].imageId}.jpg',
          //       fit: BoxFit.cover,
          //       height: 200,
          //       width: 1200,
          //     ),
          //   ),
          // ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: layout == _Layout.singleColumn
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Hero(
                      tag: '${libraryEntry.id}_cover',
                      child: CachedNetworkImage(
                        imageUrl:
                            '${Urls.imageProvider}/t_cover_big/${libraryEntry.cover}.jpg',
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: FloatingActionButton(
                        mini: true,
                        tooltip: 'Edit',
                        child: Icon(Icons.edit),
                        backgroundColor: Color.fromARGB(64, 255, 255, 255),
                        onPressed: () {
                          GameEntryEditDialog.show(context, libraryEntry);
                        },
                      ),
                    ),
                  ],
                ),
                if (layout == _Layout.twoColumns) ...[
                  Padding(padding: EdgeInsets.all(8)),
                  Expanded(
                    child: _GameTitle(libraryEntry),
                  ),
                ],
              ],
            ),
          )
        ]),
      ),
    );
  }
}

class _GameTitle extends StatelessWidget {
  final LibraryEntry libraryEntry;

  _GameTitle(this.libraryEntry);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(
            child: Text(
              libraryEntry.name,
              style: Theme.of(context).textTheme.headline3,
              textAlign: TextAlign.center,
            ),
          ),
        ]),
        Padding(padding: EdgeInsets.all(16)),
        GameTags(libraryEntry),
      ],
    );
  }
}

class _ScreenshotsSliver extends StatelessWidget {
  final GameEntry entry;
  final _Layout layout;

  const _ScreenshotsSliver(this.entry, this.layout);

  @override
  Widget build(BuildContext context) {
    return SliverGrid.count(
      crossAxisCount: layout == _Layout.twoColumns ? 2 : 1,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: entry.screenshots.isNotEmpty
          ? entry.screenshots[0].width / entry.screenshots[0].height
          : 1,
      children: [
        for (final screenshot in entry.screenshots)
          GridTile(
            child: Material(
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl:
                    '${Urls.imageProvider}/t_720p/${screenshot.imageId}.jpg',
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            ),
          ),
      ],
    );
  }
}
