import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/widgets/tiles/tile_carousel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  State<MatchingDialogContent> createState() => _MatchingDialogContentState();
}

class _MatchingDialogContentState extends State<MatchingDialogContent> {
  String storeName = 'egs';

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
                matches = context.read<UserLibraryModel>().searchByTitle(text);
              }),
              controller: _matchController,
              focusNode: _matchFocusNode,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Game title...',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: AbsorbPointer(
              absorbing: widget.storeEntry != null,
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
                hint: const Text(
                  'Storefront',
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
                Widget result = TileCarousel(
                  title: 'Matches',
                  tiles: [
                    for (var i = 0; i < 5; ++i) const TileData(),
                  ],
                  tileSize: AppConfigModel.isMobile(context)
                      ? const TileSize(width: 133, height: 190)
                      : const TileSize(width: 227, height: 320),
                );

                if (snapshot.connectionState == ConnectionState.waiting) {
                  Future.delayed(Duration.zero, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Looking up for matches...'),
                      duration: Duration(seconds: 10),
                    ));
                  });
                } else if (snapshot.hasError) {
                  result = Center(
                    child: Text('Something went wrong: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData) {
                  result = const Center(child: Text('No data'));
                } else if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  Future.delayed(Duration.zero, () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                  });

                  final gameEntries = snapshot.data!;
                  final tiles = gameEntries
                      .map((gameEntry) => TileData(
                          title: gameEntry.name,
                          image: gameEntry.cover != null
                              ? '${Urls.imageProvider}/t_cover_big/${gameEntry.cover!.imageId}.jpg'
                              : null,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Matching in progress...')));
                            widget.onMatch!(getStoreEntry(), gameEntry);
                            Navigator.of(context).pop();
                          }))
                      .toList();

                  result = tiles.isNotEmpty
                      ? TileCarousel(
                          title: 'Matches',
                          tiles: tiles,
                          tileSize: AppConfigModel.isMobile(context)
                              ? const TileSize(width: 133, height: 190)
                              : const TileSize(width: 227, height: 320),
                        )
                      : const Center(child: Text('No matches found!'));
                }

                return SizedBox(
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
    return widget.storeEntry ??
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
