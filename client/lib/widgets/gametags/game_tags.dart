import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameTags extends StatelessWidget {
  final LibraryEntry entry;

  GameTags(this.entry);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GameChipsWrap(entry),
      ],
    );
  }
}

class _GameChipsWrap extends StatelessWidget {
  final LibraryEntry entry;

  const _GameChipsWrap(this.entry);

  @override
  Widget build(BuildContext context) {
    final tagsModel = context.watch<GameTagsModel>();

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        for (final company in entry.companies)
          CompanyChip(
            company,
            onPressed: () => context.pushNamed(
              'games',
              queryParams: LibraryFilter(companies: {company}).params(),
            ),
          ),
        for (final collection in entry.collections)
          if (tagsModel.getCollectionSize(collection) > 1)
            CollectionChip(
              collection,
              onPressed: () => context.pushNamed(
                'games',
                queryParams: LibraryFilter(collections: {collection}).params(),
              ),
            ),
        for (final tag in context.watch<GameTagsModel>().tagsByEntry(entry.id))
          TagChip(
            tag,
            onPressed: () => context.pushNamed(
              'games',
              queryParams: LibraryFilter(tags: {tag}).params(),
            ),
            onDeleted: () {
              context.read<GameTagsModel>().removeUserTag(tag, entry.id);
            },
          ),
      ],
    );
  }
}

class GameCardChips extends StatelessWidget {
  final LibraryEntry entry;
  final bool includeCompanies;
  final bool includeCollections;

  const GameCardChips(
    this.entry, {
    this.includeCompanies = false,
    this.includeCollections = true,
  });

  @override
  Widget build(BuildContext context) {
    final tagsModel = context.watch<GameTagsModel>();

    return Container(
      height: 40.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (includeCompanies)
            for (final company in entry.companies)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: CompanyChip(
                  company,
                  onPressed: () => context.pushNamed(
                    'games',
                    queryParams: LibraryFilter(companies: {company}).params(),
                  ),
                ),
              ),
          if (includeCollections)
            for (final collection in entry.collections)
              if (tagsModel.getCollectionSize(collection) > 1)
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: CollectionChip(
                    collection,
                    onPressed: () => context.pushNamed(
                      'games',
                      queryParams:
                          LibraryFilter(collections: {collection}).params(),
                    ),
                  ),
                ),
          for (final tag
              in context.watch<GameTagsModel>().tagsByEntry(entry.id))
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: TagChip(
                tag,
                onPressed: () => context.pushNamed(
                  'games',
                  queryParams: LibraryFilter(tags: {tag}).params(),
                ),
                onDeleted: () {
                  context.read<GameTagsModel>().removeUserTag(tag, entry.id);
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
