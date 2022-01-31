import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameTags extends StatelessWidget {
  final LibraryEntry entry;

  GameTags(this.entry);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GameChipsBar(entry),
      // Center(
      //   child: GameTagsField(entry),
      // )
    ]);
  }
}

class GameChipsBar extends StatelessWidget {
  final LibraryEntry entry;

  const GameChipsBar(this.entry);

  @override
  Widget build(BuildContext context) {
    // Force to render the view when GameDetails (e.g. game tags) are updated.
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

class CompanyChip extends StatelessWidget {
  final Annotation company;

  const CompanyChip(this.company);

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text('${company.name} (${company.id})'),
      backgroundColor: Colors.redAccent,
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/games',
          arguments: LibraryFilter(companies: {company}).encode(),
        );
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
        Navigator.pushNamed(
          context,
          '/games',
          arguments: LibraryFilter(collections: {collection}).encode(),
        );
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

class StoreChip extends StatelessWidget {
  final StoreEntry store;

  const StoreChip(this.store);

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(store.storefront),
      backgroundColor: Colors.purple[800],
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/games',
          arguments: LibraryFilter(stores: {store.storefront}).encode(),
        );
      },
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
      onPressed: () {},
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
