import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/widgets/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameTags extends StatelessWidget {
  final LibraryEntry entry;

  GameTags(this.entry);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GameChipsWrap(entry),
      // Center(
      //   child: GameTagsField(entry),
      // )
    ]);
  }
}

class GameChipsWrap extends StatelessWidget {
  final LibraryEntry entry;

  const GameChipsWrap(this.entry);

  @override
  Widget build(BuildContext context) {
    // Forces the widget to rebuild when library entries update (e.g. tags).
    context.watch<GameLibraryModel>();

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        for (final company in entry.companies) CompanyChip(company),
        if (entry.collection != null) CollectionChip(entry.collection!),
        for (final franchise in entry.franchises) FranchiseChip(franchise),
        for (final tag in entry.userData.tags) TagChip(tag: tag, entry: entry),
      ],
    );
  }
}

class GameChipsListView extends StatelessWidget {
  final LibraryEntry entry;

  const GameChipsListView(this.entry);

  @override
  Widget build(BuildContext context) {
    // Forces the widget to rebuild when library entries update (e.g. tags).
    context.watch<GameLibraryModel>();

    return Container(
      height: 40.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final company in entry.companies)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: CompanyChip(company),
            ),
          if (entry.collection != null)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: CollectionChip(entry.collection!),
            ),
          for (final franchise in entry.franchises)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: FranchiseChip(franchise),
            ),
          for (final tag in entry.userData.tags)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: TagChip(tag: tag, entry: entry),
            ),
        ],
      ),
    );
  }
}
