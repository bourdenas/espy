import 'package:espy/constants/urls.dart';
import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MatchingDialog extends StatefulWidget {
  static void show(BuildContext context, StoreEntry entry) {
    showDialog(
      context: context,
      builder: (context) => MatchingDialog(entry),
    );
  }

  final StoreEntry storeEntry;

  MatchingDialog(this.storeEntry);

  @override
  State<MatchingDialog> createState() => _MatchingDialogState();
}

class _MatchingDialogState extends State<MatchingDialog>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 450));
    _scalingAnimation = CurvedAnimation(
        parent: _animationController, curve: Curves.elasticInOut);
    _animationController.addListener(() {
      setState(() {});
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scalingAnimation,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: TextEditingController()
                  ..text = widget.storeEntry.title,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Title',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _GameMatchTextField(widget.storeEntry),
            ),
          ],
        ),
      ),
    );
  }

  late AnimationController _animationController;
  late Animation<double> _scalingAnimation;
}

class _GameMatchTextField extends StatefulWidget {
  final StoreEntry storeEntry;

  const _GameMatchTextField(this.storeEntry);

  @override
  State<StatefulWidget> createState() => _GameMatchTextFieldState(storeEntry);
}

class _GameMatchTextFieldState extends State<_GameMatchTextField> {
  StoreEntry storeEntry;

  _GameMatchTextFieldState(this.storeEntry);

  final TextEditingController _matchController = TextEditingController();
  final FocusNode _matchFocusNode = FocusNode();
  final LayerLink _matchLayerLink = LayerLink();
  OverlayEntry? _matchOverlay;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _matchLayerLink,
      child: TextField(
        onSubmitted: (text) async {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blueAccent)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8)),
                Text('Looking up for matches...'),
              ],
            ),
            duration: Duration(milliseconds: 30000),
          ));
          final entries =
              await context.read<GameLibraryModel>().searchByTitle(text);

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          if (entries.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No matches were found.')));
          }
          setState(() {
            _matchOverlay = _createMatchSuggestions(entries);
            Overlay.of(context)!.insert(_matchOverlay!);
          });
        },
        controller: _matchController,
        focusNode: _matchFocusNode,
        autofocus: kIsWeb,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'match...',
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

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
                                    "Matching '${storeEntry.title}' with '${game.name}'..."),
                              ],
                            )));

                            await context
                                .read<GameLibraryModel>()
                                .matchEntry(storeEntry, game);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ));
  }
}
