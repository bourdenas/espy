import 'package:espy/proto/library.pb.dart' show GameEntry, GameDetails;
import 'package:flutter/material.dart';

class GameTags extends StatefulWidget {
  final GameEntry entry;

  const GameTags(this.entry);

  @override
  State<StatefulWidget> createState() => GameTagsState(entry);
}

class GameTagsState extends State<GameTags> {
  final GameEntry entry;

  GameTagsState(this.entry);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          for (final tag in entry.details.tag)
            InputChip(
              label: Text(tag),
              onPressed: () {},
              onDeleted: () => setState(() {
                entry.details.tag.remove(tag);
              }),
            ),
        ],
      ),
      Center(
        child: Container(
          width: 200,
          child: TextField(
            onSubmitted: (tag) => setState(() {
              // NB: I don't get it why just "entry.details.tag.add(tag);"
              // fails and I need to clone GameDetails to edit it.
              entry.details = GameDetails()
                ..mergeFromMessage(entry.details)
                ..tag.add(tag);
              _tagsController.clear();
              _tagsFocusNode.requestFocus();
            }),
            controller: _tagsController,
            focusNode: _tagsFocusNode,
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.tag),
              hintText: 'tags...',
            ),
          ),
        ),
      )
    ]);
  }

  final TextEditingController _tagsController = TextEditingController();
  final FocusNode _tagsFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tagsController.dispose();
    super.dispose();
  }
}
