import 'package:espy/proto/library.pb.dart' show GameEntry;
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
          for (final tag in _tags)
            InputChip(
              label: Text(tag),
              onPressed: () {},
              onDeleted: () => setState(() {
                _tags.remove(tag);
              }),
            ),
        ],
      ),
      Center(
        child: Container(
          width: 200,
          child: TextField(
            onSubmitted: (tag) => setState(() {
              _tags.add(tag);
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

  final Set<String> _tags = {
    '4X',
    'Strategy',
    'Amplitude',
    'Turn-Based Strategy'
  };
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
