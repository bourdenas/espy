import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/appbar_search_model.dart';
import 'package:espy/modules/models/game_details_model.dart';
import 'package:espy/modules/models/library_filters_model.dart';
import 'package:espy/widgets/details/game_tags_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameTags extends StatelessWidget {
  final LibraryEntry entry;

  GameTags(this.entry);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GameChipsBar(entry),
      Center(
        child: GameTagsTextField(entry),
      )
    ]);
  }
}

class GameChipsBar extends StatelessWidget {
  final LibraryEntry entry;

  const GameChipsBar(this.entry);

  @override
  Widget build(BuildContext context) {
    // Force to render the view when GameDetails (e.g. game tags) are updated.
    context.watch<GameDetailsModel>();

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        for (final company in entry.companies) CompanyChip(company),
        if (entry.collection != null) CollectionChip(entry.collection!),
        for (final franchise in entry.franchises) FranchiseChip(franchise),
        for (final tag in entry.userData.tags) TagChip(tag, entry),
      ],
    );
  }
}

class CompanyChip extends StatelessWidget {
  final Annotation company;

  const CompanyChip(this.company);

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text('${company.name} (${company.id})'),
      backgroundColor: Colors.red[900],
      onPressed: () {
        context.read<LibraryFiltersModel>().addCompanyFilter(company);
        context.read<AppBarSearchModel>().clear();
        Navigator.pop(context);
      },
    );
  }
}

class CollectionChip extends StatelessWidget {
  final Annotation collection;

  const CollectionChip(this.collection);

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text('${collection.name} (${collection.id})'),
      backgroundColor: Colors.indigo[800],
      onPressed: () {
        context.read<LibraryFiltersModel>().addCollectionFilter(collection);
        context.read<AppBarSearchModel>().clear();
        Navigator.pop(context);
      },
    );
  }
}

class FranchiseChip extends StatelessWidget {
  final Annotation franchise;

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
  final LibraryEntry entry;

  const TagChip(this.tag, this.entry);

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(tag),
      onPressed: () {
        context.read<LibraryFiltersModel>().addTagFilter(tag);
        context.read<AppBarSearchModel>().clear();
        // TODO: Depending which screen the TagChip is present, this shouldn't
        // be poping always.
        Navigator.pop(context);
      },
      onDeleted: () {
        if (entry.userData.tags.isEmpty) return;
        entry.userData.tags.remove(tag);
        context.read<GameDetailsModel>().postDetails(entry);
      },
    );
  }
}
