import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CompanyChip extends StatelessWidget {
  final Annotation company;

  const CompanyChip(this.company);

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text('${company.name}'),
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
      label: Text('${collection.name}'),
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
      label: Text('${franchise.name}'),
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
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/games',
          arguments: LibraryFilter(tags: {tag}).encode(),
        );
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
