import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/proto/library.pb.dart' show GameEntry, GameDetails;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          for (final involved in entry.game.involvedCompanies)
            if (involved.developer)
              InputChip(
                label:
                    Text('${involved.company.name} (${involved.company.id})'),
                backgroundColor: Colors.red[700],
                onPressed: () {
                  context.read<GameLibraryModel>().companyFilter =
                      involved.company.id;
                  Navigator.pop(context);
                },
              ),
          if (entry.game.hasCollection())
            InputChip(
              label: Text(
                  '${entry.game.collection.name} (${entry.game.collection.id})'),
              backgroundColor: Colors.indigo[700],
              onPressed: () {
                context.read<GameLibraryModel>().collectionFilter =
                    entry.game.collection.id;
                Navigator.pop(context);
              },
            ),
          for (final franchise in entry.game.franchises)
            InputChip(
              label: Text('${franchise.name} (${franchise.id})'),
              backgroundColor: Colors.yellow[800],
              onPressed: () {},
            ),
          for (final tag in entry.details.tag)
            InputChip(
              label: Text(tag),
              onPressed: () {
                context.read<GameLibraryModel>().tag = tag;
                Navigator.pop(context);
              },
              onDeleted: () => setState(() {
                entry.details.tag.remove(tag);
                context.read<GameLibraryModel>().postDetails(entry);
              }),
            ),
        ],
      ),
      Center(
        child: Container(
          width: 200,
          child: TextField(
            onSubmitted: (tag) => setState(() {
              if (tag.isEmpty) {
                _tagsFocusNode.requestFocus();
                return;
              }

              // NB: I don't get it why just "entry.details.tag.add(tag);"
              // fails and I need to clone GameDetails to edit it.
              entry.details = GameDetails()
                ..mergeFromMessage(entry.details)
                ..tag.add(tag);
              _tagsController.clear();
              _tagsFocusNode.requestFocus();
              context.read<GameLibraryModel>().postDetails(entry);
            }),
            controller: _tagsController,
            focusNode: _tagsFocusNode,
            autofocus: kIsWeb,
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
