import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/pages/home/slate_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MatchingTextField extends StatefulWidget {
  final StoreEntry storeEntry;

  const MatchingTextField(this.storeEntry);

  @override
  State<StatefulWidget> createState() => _MatchingTextFieldState();
}

class _MatchingTextFieldState extends State<MatchingTextField> {
  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _matchLayerLink,
      child: Column(
        children: [
          TextField(
            onSubmitted: (text) => _fetchMatches(text),
            controller: _matchController,
            focusNode: _matchFocusNode,
            autofocus: kIsWeb,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'match...',
            ),
          ),
        ],
      ),
    );
  }

  Future<List<GameEntry>> _fetchMatches(String text) async {
    return context.read<GameLibraryModel>().searchByTitle(text);

    // ScaffoldMessenger.of(context).hideCurrentSnackBar();
    // if (entries.isEmpty) {
    //   ScaffoldMessenger.of(context)
    //       .showSnackBar(SnackBar(content: Text('No matches were found.')));
    // }
    // setState(() {
    //   _matchOverlay = _createMatchSuggestions(entries);
    //   Overlay.of(context)!.insert(_matchOverlay!);
    // });
  }

  late Future<List<GameEntry>> entries;

  @override
  void initState() {
    super.initState();

    _matchController.text = widget.storeEntry.title;
    _matchController.addListener(() {
      if (_matchOverlay == null) {
        return;
      }

      _matchOverlay!.remove();
      _matchOverlay = null;
    });
  }

  @override
  void dispose() {
    _matchController.dispose();
    super.dispose();
  }

  final TextEditingController _matchController = TextEditingController();
  final FocusNode _matchFocusNode = FocusNode();
  final LayerLink _matchLayerLink = LayerLink();
  OverlayEntry? _matchOverlay;

  OverlayEntry _createMatchSuggestions(Iterable<GameEntry> suggestions) {
    final size = context.size!;

    return OverlayEntry(
        builder: (context) => Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _matchLayerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, size.height + 5.0),
                child: Material(
                  elevation: 4.0,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [
                      for (final game in suggestions)
                        ListTile(
                          leading: CircleAvatar(
                              foregroundImage: game.cover != null
                                  ? NetworkImage(
                                      '${Urls.imageProvider}/t_thumb/${game.cover!.imageId}.jpg')
                                  : null),
                          title: Text(game.name),
                          trailing: Text(
                              '${DateTime.fromMillisecondsSinceEpoch(game.releaseDate * 1000).year}'),
                          onTap: () async {
                            _matchOverlay!.remove();
                            _matchOverlay = null;
                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Row(
                              children: [
                                CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blueAccent)),
                                Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8)),
                                Text(
                                    "Matching '${widget.storeEntry.title}' with '${game.name}'..."),
                              ],
                            )));

                            await context
                                .read<GameLibraryModel>()
                                .matchEntry(widget.storeEntry, game);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ));
  }
}
