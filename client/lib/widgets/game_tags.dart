import 'package:espy/modules/models/appbar_search_model.dart';
import 'package:espy/modules/models/game_details_model.dart';
import 'package:espy/modules/models/library_filters_model.dart';
import 'package:espy/proto/igdbapi.pb.dart' show Collection, Company, Franchise;
import 'package:espy/proto/library.pb.dart' show GameEntry;
import 'package:espy/widgets/game_tags_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameTags extends StatelessWidget {
  final GameEntry entry;

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
        context.read<LibraryFiltersModel>().addCompanyFilter(company);
        context.read<AppBarSearchModel>().clear();
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
        context.read<LibraryFiltersModel>().addCollectionFilter(collection);
        context.read<AppBarSearchModel>().clear();
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
        context.read<LibraryFiltersModel>().addTagFilter(tag);
        context.read<AppBarSearchModel>().clear();
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
