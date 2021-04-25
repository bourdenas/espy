import 'package:espy/modules/models/game_details_model.dart';
import 'package:espy/proto/library.pb.dart' show GameEntry;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameTagsTextField extends StatefulWidget {
  final GameEntry entry;

  const GameTagsTextField(this.entry);

  @override
  State<StatefulWidget> createState() => GameTagsTextFieldState(entry);
}

class GameTagsTextFieldState extends State<GameTagsTextField> {
  GameEntry entry;

  GameTagsTextFieldState(this.entry);

  final TextEditingController _tagsController = TextEditingController();
  final FocusNode _tagsFocusNode = FocusNode();
  final LayerLink _suggestionsLayerLink = LayerLink();
  OverlayEntry? _suggestionsOverlay;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
        link: _suggestionsLayerLink,
        child: Container(
          width: 200,
          child: TextField(
            onSubmitted: (tag) => setState(() {
              _postTag(tag);
            }),
            controller: _tagsController,
            focusNode: _tagsFocusNode,
            autofocus: kIsWeb,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.tag),
              hintText: 'tags...',
            ),
          ),
        ));
  }

  @override
  void initState() {
    super.initState();

    _tagsController.addListener(() {
      if (_suggestionsOverlay != null) {
        _suggestionsOverlay!.remove();
        _suggestionsOverlay = null;
      }

      if (_tagsController.text.isNotEmpty) {
        final prefix = _tagsController.text.toLowerCase();
        final suggestions = context
            .read<GameDetailsModel>()
            .tags
            .where((tag) => tag.toLowerCase().startsWith(prefix))
            .take(3);
        _suggestionsOverlay = _createSuggestions(suggestions);
        Overlay.of(context)!.insert(_suggestionsOverlay!);
      }
    });

    _tagsFocusNode.addListener(() {
      if (!_tagsFocusNode.hasFocus && _suggestionsOverlay != null) {
        _suggestionsOverlay!.remove();
        _suggestionsOverlay = null;
      }
    });
  }

  @override
  void dispose() {
    _tagsController.dispose();
    super.dispose();
  }

  OverlayEntry _createSuggestions(Iterable<String> suggestions) {
    final size = context.size!;

    return OverlayEntry(
        builder: (context) => Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _suggestionsLayerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, size.height + 5.0),
                child: Material(
                  elevation: 4.0,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [
                      for (final tag in suggestions)
                        ListTile(
                          title: Text(tag),
                          onTap: () => _postTag(tag),
                        ),
                    ],
                  ),
                ),
              ),
            ));
  }

  void _postTag(String tag) {
    if (tag.isEmpty) {
      _tagsFocusNode.requestFocus();
      return;
    }

    // // NB: I don't get it why just "entry.details.tag.add(tag);"
    // // fails and I need to clone GameDetails to edit it.
    // entry.details = GameDetails()
    //   ..mergeFromMessage(entry.details)
    //   ..tag.add(tag);
    entry.details.tag.add(tag);

    _tagsController.clear();
    _tagsFocusNode.requestFocus();
    context.read<GameDetailsModel>().postDetails(entry);
  }
}
