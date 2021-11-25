import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/routing/library_filter.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/details/game_tags_field.dart';
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
        child: GameTagsField(entry),
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
    // context.watch<GameLibraryModel>();

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

class CompanyChip extends StatelessWidget {
  final Annotation company;

  const CompanyChip(this.company);

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text('${company.name} (${company.id})'),
      backgroundColor: Colors.red[900],
      onPressed: () {
        context.read<GameLibraryModel>().fetchAll();
        context
            .read<EspyRouterDelegate>()
            .showFilter(LibraryFilter()..companies.add(company));
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
        context.read<GameLibraryModel>().fetchAll();
        context
            .read<EspyRouterDelegate>()
            .showFilter(LibraryFilter()..collections.add(collection));
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
  final LibraryEntry? entry;

  const TagChip({required this.tag, this.entry});

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(tag),
      onPressed: () async {
        context.read<GameLibraryModel>().fetchAll();
        context
            .read<EspyRouterDelegate>()
            .showFilter(LibraryFilter()..tags.add(tag));
      },
      onDeleted: entry != null
          ? () {
              if (entry!.userData.tags.isEmpty) return;
              entry!.userData.tags.remove(tag);
              context.read<GameLibraryModel>().postDetails(entry!);
            }
          : null,
    );
  }
}
