import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/widgets/image_carousel.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class MatchingDialogContent extends StatefulWidget {
  const MatchingDialogContent(
    this.storeEntry,
    this.matches, {
    Key? key,
    this.onMatch,
  }) : super(key: key);

  final StoreEntry? storeEntry;
  final Future<List<GameEntry>> matches;
  final void Function(StoreEntry, GameEntry)? onMatch;

  @override
  State<MatchingDialogContent> createState() =>
      _MatchingDialogContentState(storeEntry);
}

class _MatchingDialogContentState extends State<MatchingDialogContent> {
  StoreEntry? storeEntry;
  String storeName = 'egs';

  _MatchingDialogContentState(this.storeEntry);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onSubmitted: (text) => setState(() {
                matches = context.read<GameLibraryModel>().searchByTitle(text);
              }),
              controller: _matchController,
              focusNode: _matchFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Game title...',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: AbsorbPointer(
              absorbing: storeEntry != null,
              child: DropdownButton<String>(
                value: storeName,
                items: [
                  for (final store in [
                    'gog',
                    'steam',
                    'egs',
                    'battle.net',
                    'disc',
                  ])
                    DropdownMenuItem<String>(
                      value: store,
                      child: Text(store),
                    ),
                ],
                hint: Text(
                  "Storefront",
                ),
                onChanged: (String? value) {
                  setState(() {
                    storeName = value!;
                  });
                },
              ),
            ),
          ),
          FutureBuilder(
              future: matches,
              builder: (context, snapshot) {
                Widget result = ImageCarousel(
                  title: 'Matches',
                  tiles: [
                    for (var i = 0; i < 5; ++i) CarouselTileData(),
                  ],
                  tileSize: AppConfigModel.isMobile(context)
                      ? TileSize(width: 133, height: 190)
                      : TileSize(width: 227, height: 320),
                );

                if (snapshot.connectionState == ConnectionState.waiting) {
                  Future.delayed(Duration.zero, () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Looking up for matches...'),
                      duration: Duration(seconds: 10),
                    ));
                  });
                } else if (snapshot.hasError) {
                  result = Center(
                    child: Text('Something went wrong: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData) {
                  result = Center(child: Text('No data'));
                } else if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  Future.delayed(Duration.zero, () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                  });

                  final gameEntries = snapshot.data! as List<GameEntry>;
                  final tiles = gameEntries
                      .map((gameEntry) => CarouselTileData(
                          title: gameEntry.name,
                          image: gameEntry.cover != null
                              ? '${Urls.imageProvider}/t_cover_big/${gameEntry.cover!.imageId}.jpg'
                              : null,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Matching in progress...')));
                            widget.onMatch!(getStoreEntry(), gameEntry);
                            Navigator.of(context).pop();
                          }))
                      .toList();

                  result = tiles.isNotEmpty
                      ? ImageCarousel(
                          title: 'Matches',
                          tiles: tiles,
                          tileSize: AppConfigModel.isMobile(context)
                              ? TileSize(width: 133, height: 190)
                              : TileSize(width: 227, height: 320),
                        )
                      : Center(child: Text('No matches found!'));
                }

                return Container(
                  // hacky: Manually measure height of HomeSlate to avoid
                  // resize if a message is shown instead.
                  height: 400.0,
                  width: 500.0,
                  child: result,
                );
              }),
        ],
      ),
    );
  }

  StoreEntry getStoreEntry() {
    return storeEntry ??
        StoreEntry(
          id: '',
          title: _matchController.text,
          storefront: storeName,
        );
  }

  @override
  void initState() {
    super.initState();

    matches = widget.matches;
    _matchController.text = widget.storeEntry?.title ?? '';
  }

  @override
  void dispose() {
    _matchController.dispose();
    super.dispose();
  }

  late Future<List<GameEntry>> matches;

  final TextEditingController _matchController = TextEditingController();
  final FocusNode _matchFocusNode = FocusNode();
}
