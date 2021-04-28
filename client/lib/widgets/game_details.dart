// import 'dart:ui' as ui;
import 'package:espy/constants/urls.dart';
import 'package:espy/proto/library.pb.dart';
import 'package:espy/widgets/game_tags.dart';
import 'package:espy/widgets/library/game_entry_edit_dialog.dart';
import 'package:flutter/material.dart';

class GameDetails extends StatelessWidget {
  final GameEntry entry;

  GameDetails({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final layout = constraints.maxWidth < 1200
          ? _Layout.singleColumn
          : _Layout.twoColumns;
      return Scaffold(
          body: CustomScrollView(
        slivers: [
          _HeaderSliver(entry, layout),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Column(children: [
                  if (layout == _Layout.singleColumn) ...[
                    Padding(padding: const EdgeInsets.all(16)),
                    _GameTitle(entry),
                  ],
                  Container(
                    padding: const EdgeInsets.all(32),
                    child: Text(entry.game.summary),
                  )
                ]);
              },
              childCount: 1,
            ),
          ),
          _ScreenshotsSliver(entry, layout),
        ],
      ));
    });
  }
}

enum _Layout {
  singleColumn,
  twoColumns,
}

class _HeaderSliver extends StatelessWidget {
  final GameEntry entry;
  final _Layout layout;

  const _HeaderSliver(this.entry, this.layout);

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
                      tag: '${entry.game.id}_cover',
                      child: Image.network(
                        '${Urls.imageProvider}/t_cover_big/${entry.game.cover.imageId}.jpg',
                        fit: BoxFit.cover,
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
                          GameEntryEditDialog.show(context, entry);
                        },
                      ),
                    ),
                  ],
                ),
                if (layout == _Layout.twoColumns) ...[
                  Padding(padding: EdgeInsets.all(8)),
                  Expanded(
                    child: _GameTitle(entry),
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
  final GameEntry entry;

  _GameTitle(this.entry);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(
            child: Text(
              entry.game.name,
              style: Theme.of(context).textTheme.headline3,
              textAlign: TextAlign.center,
            ),
          ),
        ]),
        Padding(padding: EdgeInsets.all(16)),
        GameTags(entry),
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
      childAspectRatio: entry.game.screenshots.isNotEmpty
          ? entry.game.screenshots[0].width / entry.game.screenshots[0].height
          : 1,
      children: [
        for (final screenshot in entry.game.screenshots)
          GridTile(
            child: Material(
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                '${Urls.imageProvider}/t_720p/${screenshot.imageId}.jpg',
                fit: BoxFit.contain,
              ),
            ),
          ),
      ],
    );
  }
}
