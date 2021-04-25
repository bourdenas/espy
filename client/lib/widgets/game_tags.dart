import 'package:espy/modules/models/game_details_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/proto/igdbapi.pb.dart' show Collection, Company, Franchise;
import 'package:espy/proto/library.pb.dart' show GameDetails, GameEntry;
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
      GameChipsBar(entry),
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
              context.read<GameDetailsModel>().postDetails(entry);
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

class GameChipsBar extends StatelessWidget {
  final GameEntry entry;

  const GameChipsBar(this.entry);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        for (final involved in entry.game.involvedCompanies)
          if (involved.developer) CompanyChip(involved.company),
        if (entry.game.hasCollection()) CollectionChip(entry.game.collection),
        for (final franchise in entry.game.franchises) FranchiseChip(franchise),
        for (final tag in entry.details.tag) TagChip(tag, entry),
      ],
    );
  }
}

class CompanyChip extends StatelessWidget {
  final Company company;

  const CompanyChip(this.company);

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text('${company.name} (${company.id})'),
      backgroundColor: Colors.red[900],
      onPressed: () {
        context.read<GameEntriesModel>().addCompanyFilter(company);
        Navigator.pop(context);
      },
    );
  }
}

class CollectionChip extends StatelessWidget {
  final Collection collection;

  const CollectionChip(this.collection);

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text('${collection.name} (${collection.id})'),
      backgroundColor: Colors.indigo[800],
      onPressed: () {
        context.read<GameEntriesModel>().addCollectionFilter(collection);
        Navigator.pop(context);
      },
    );
  }
}

class FranchiseChip extends StatelessWidget {
  final Franchise franchise;

  const FranchiseChip(this.franchise);

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text('${franchise.name} (${franchise.id})'),
      onPressed: () {},
      backgroundColor: Colors.yellow[800],
    );
  }
}

class TagChip extends StatelessWidget {
  final String tag;
  final GameEntry entry;

  const TagChip(this.tag, this.entry);

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(tag),
      onPressed: () {
        context.read<GameEntriesModel>().addTagFilter(tag);
        Navigator.pop(context);
      },
      onDeleted: () {
        if (entry.details.tag.isEmpty) return;
        entry.details.tag.remove(tag);
        context.read<GameDetailsModel>().postDetails(entry);
      },
    );
  }
}
