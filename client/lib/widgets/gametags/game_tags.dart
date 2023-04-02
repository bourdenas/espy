import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameTags extends StatelessWidget {
  final GameEntry? gameEntry;
  final LibraryEntry? libraryEntry;

  GameTags({this.gameEntry, this.libraryEntry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GameChipsWrap(
          gameEntry: gameEntry,
          libraryEntry: libraryEntry,
        ),
      ],
    );
  }
}

extractTags(GameEntry? gameEntry, LibraryEntry? libraryEntry) {
  return {
    'gameId': gameEntry != null ? gameEntry.id : libraryEntry?.id ?? 0,
    'developers': gameEntry != null
        ? gameEntry.companies
            .where((e) => e.role == "Developer")
            .map((e) => e.name)
        : libraryEntry?.companies ?? [],
    'publishers': gameEntry != null
        ? gameEntry.companies
            .where((e) => e.role != "Developer")
            .map((e) => e.name)
        : <String>[],
    'collections': gameEntry != null
        ? gameEntry.collections.map((e) => e.name).toSet()
        : libraryEntry?.collections ?? [],
  };
}

class _GameChipsWrap extends StatelessWidget {
  final GameEntry? gameEntry;
  final LibraryEntry? libraryEntry;

  const _GameChipsWrap({this.gameEntry, this.libraryEntry});

  @override
  Widget build(BuildContext context) {
    final tagsModel = context.watch<GameTagsModel>();
    final tags = extractTags(gameEntry, libraryEntry);

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        for (final company in tags['developers'])
          CompanyChip(
            company,
            onPressed: () => context.pushNamed(
              'games',
              queryParams: LibraryFilter(companies: {company}).params(),
            ),
          ),
        for (final company in tags['publishers'])
          CompanyChip(
            company,
            developer: false,
            onPressed: () => context.pushNamed(
              'games',
              queryParams: LibraryFilter(companies: {company}).params(),
            ),
          ),
        for (final collection in tags['collections'])
          if (tagsModel.collections.size(collection) > 1)
            CollectionChip(
              collection,
              onPressed: () => context.pushNamed(
                'games',
                queryParams: LibraryFilter(collections: {collection}).params(),
              ),
            ),
        for (final tag
            in context.watch<GameTagsModel>().userTags.byGameId(tags['gameId']))
          TagChip(
            tag,
            onPressed: () => context.pushNamed(
              'games',
              queryParams: LibraryFilter(tags: {tag.name}).params(),
            ),
            onDeleted: () => context
                .read<GameTagsModel>()
                .userTags
                .remove(tag, tags['gameId']),
            onRightClick: () =>
                context.read<GameTagsModel>().userTags.moveCluster(tag),
          ),
      ],
    );
  }
}

class GameCardChips extends StatelessWidget {
  final LibraryEntry? libraryEntry;
  final GameEntry? gameEntry;
  final bool includeCompanies;
  final bool includeCollections;

  const GameCardChips({
    this.libraryEntry,
    this.gameEntry,
    this.includeCompanies = false,
    this.includeCollections = true,
  });

  @override
  Widget build(BuildContext context) {
    final tagsModel = context.watch<GameTagsModel>();
    final tags = extractTags(gameEntry, libraryEntry);

    return Container(
      height: 40.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (includeCompanies) ...[
            for (final company in tags['developers'])
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
            for (final company in tags['publishers'])
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: CompanyChip(
                  company,
                  developer: false,
                  onPressed: () => context.pushNamed(
                    'games',
                    queryParams: LibraryFilter(companies: {company}).params(),
                  ),
                ),
              ),
          ],
          if (includeCollections)
            for (final collection in tags['collections'])
              if (tagsModel.collections.size(collection) > 1)
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
          for (final tag in tagsModel.userTags.byGameId(tags['gameId']))
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: TagChip(
                tag,
                onPressed: () => context.pushNamed(
                  'games',
                  queryParams: LibraryFilter(tags: {tag.name}).params(),
                ),
                onDeleted: () => context
                    .read<GameTagsModel>()
                    .userTags
                    .remove(tag, tags['gameId']),
                onRightClick: () =>
                    context.read<GameTagsModel>().userTags.moveCluster(tag),
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
          child: TagChip(context.read<GameTagsModel>().userTags.get(tag),
              onDeleted: () {}),
        ),
      ],
    ]);
  }
}
