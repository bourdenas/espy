import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:espy/widgets/gametags/game_tags_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameTags extends StatelessWidget {
  final LibraryEntry entry;

  GameTags(this.entry);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GameChipsWrap(entry),
        // GameTagsField(entry),
      ],
    );
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
        for (final company in entry.companies)
          CompanyChip(
            company,
            onPressed: () => Navigator.pushNamed(
              context,
              '/games',
              arguments: LibraryFilter(companies: {company}).encode(),
            ),
          ),
        if (entry.collection != null)
          CollectionChip(
            entry.collection!,
            onPressed: () => Navigator.pushNamed(
              context,
              '/games',
              arguments:
                  LibraryFilter(collections: {entry.collection!}).encode(),
            ),
          ),
        for (final franchise in entry.franchises) FranchiseChip(franchise),
        for (final tag in entry.userData.tags)
          TagChip(
            tag,
            onPressed: () => Navigator.pushNamed(
              context,
              '/games',
              arguments: LibraryFilter(tags: {tag}).encode(),
            ),
            onDeleted: () {
              entry.userData.tags.remove(tag);
              context.read<GameLibraryModel>().postDetails(entry);
            },
          ),
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
              child: CompanyChip(
                company,
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/games',
                  arguments: LibraryFilter(companies: {company}).encode(),
                ),
              ),
            ),
          if (entry.collection != null)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: CollectionChip(
                entry.collection!,
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/games',
                  arguments:
                      LibraryFilter(collections: {entry.collection!}).encode(),
                ),
              ),
            ),
          for (final franchise in entry.franchises)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: FranchiseChip(franchise),
            ),
          for (final tag in entry.userData.tags)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: TagChip(
                tag,
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/games',
                  arguments: LibraryFilter(tags: {tag}).encode(),
                ),
                onDeleted: () {
                  entry.userData.tags.remove(tag);
                  context.read<GameLibraryModel>().postDetails(entry);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class GameChipsFilter extends StatelessWidget {
  GameChipsFilter(this.filter);

  final LibraryFilter filter;

  @override
  Widget build(BuildContext context) {
    if (filter.isEmpty) {
      return Row(children: []);
    }

    return Row(children: [
      for (final store in filter.stores) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: StoreChip(store, onDeleted: () {}),
        ),
      ],
      for (final company in filter.companies) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: CompanyChip(company, onDeleted: () {}),
        ),
      ],
      for (final collection in filter.collections) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: CollectionChip(collection, onDeleted: () {}),
        ),
      ],
      for (final tag in filter.tags) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: TagChip(tag, onDeleted: () {}),
        ),
      ],
    ]);
  }
}
