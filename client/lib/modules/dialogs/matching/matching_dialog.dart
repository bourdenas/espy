import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/pages/home/home_slate.dart';
import 'package:espy/pages/home/slate_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class SearchMatch extends StatefulWidget {
  static void show(BuildContext context, StoreEntry entry) {
    showDialog(
      context: context,
      builder: (context) => SearchMatch(storeEntry: entry),
    );
  }

  const SearchMatch({Key? key, required this.storeEntry}) : super(key: key);

  final StoreEntry storeEntry;

  @override
  State<SearchMatch> createState() => _SearchMatchState();
}

class _SearchMatchState extends State<SearchMatch> {
  @override
  Widget build(BuildContext context) {
    return MatchingDialog(
        widget.storeEntry, _fetchMatches(widget.storeEntry.title));
  }

  Future<List<GameEntry>> _fetchMatches(String text) async {
    return context.read<GameLibraryModel>().searchByTitle(text);
  }
}

class MatchingDialog extends StatefulWidget {
  MatchingDialog(this.storeEntry, this.matches);

  final StoreEntry storeEntry;
  final Future<List<GameEntry>> matches;

  @override
  State<MatchingDialog> createState() => _MatchingDialogState();
}

class _MatchingDialogState extends State<MatchingDialog>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    matches = widget.matches;

    _matchController.text = widget.storeEntry.title;
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _scalingAnimation = CurvedAnimation(
        parent: _animationController, curve: Curves.elasticInOut);
    _animationController.addListener(() {
      setState(() {});
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _matchController.dispose();
    super.dispose();
  }

  late Future<List<GameEntry>> matches;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scalingAnimation,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 170,
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 2.0,
                  spreadRadius: 0.0,
                  offset: Offset(2.0, 2.0), // shadow direction: bottom right
                )
              ]),
              child: SlateTile(
                  data: SlateTileData(title: widget.storeEntry.title)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onSubmitted: (text) => setState(() {
                  matches =
                      context.read<GameLibraryModel>().searchByTitle(text);
                }),
                controller: _matchController,
                focusNode: _matchFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'match...',
                ),
              ),
            ),
            FutureBuilder(
                future: matches,
                builder: (context, snapshot) {
                  Widget result = HomeSlate(title: 'Matches', tiles: [
                    for (var i = 0; i < 5; ++i) SlateTileData(),
                  ]);

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    print('Looking up for matches...');
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
                        .map((gameEntry) => SlateTileData(
                            title: gameEntry.name,
                            image: gameEntry.cover != null
                                ? '${Urls.imageProvider}/t_cover_big/${gameEntry.cover!.imageId}.jpg'
                                : null))
                        .toList();

                    result = tiles.isNotEmpty
                        ? HomeSlate(title: 'Matches', tiles: tiles)
                        : Center(child: Text('No matches found!'));
                  }

                  return Container(
                    // hacky: Manually measure height of HomeSlate to avoid
                    // resize if a message is shown instead.
                    height: 234.0,
                    width: 500.0,
                    child: result,
                  );
                }),
          ],
        ),
      ),
    );
  }

  final TextEditingController _matchController = TextEditingController();
  final FocusNode _matchFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _scalingAnimation;
}
