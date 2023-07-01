import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameTags extends StatelessWidget {
  final GameEntry? gameEntry;
  final LibraryEntry? libraryEntry;

  const GameTags({Key? key, this.gameEntry, this.libraryEntry})
      : super(key: key);

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
        ? gameEntry.developers.map((e) => e.name)
        : libraryEntry?.developers ?? [],
    'publishers': gameEntry != null
        ? gameEntry.publishers.map((e) => e.name)
        : libraryEntry?.publishers ?? [],
    'collections': gameEntry != null
        ? gameEntry.collections.map((e) => e.name).toSet()
        : libraryEntry?.collections ?? [],
    'franchises': gameEntry != null
        ? gameEntry.franchises.map((e) => e.name).toSet()
        : libraryEntry?.franchises ?? [],
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
          DeveloperChip(
            company,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
              context.pushNamed(
                'games',
                queryParameters: LibraryFilter(developers: {company}).params(),
              );
            },
          ),
        for (final company in tags['publishers'])
          PublisherChip(
            company,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
              context.pushNamed(
                'games',
                queryParameters: LibraryFilter(publishers: {company}).params(),
              );
            },
          ),
        for (final collection in tags['collections'])
          CollectionChip(
            collection,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
              final filter = context
                  .read<LibraryFilterModel>()
                  .filter
                  .add(LibraryFilter(collections: {collection}));
              context.pushNamed(
                'games',
                queryParameters: filter.params(),
              );
            },
          ),
        for (final franchise in tags['franchises'])
          FranchiseChip(
            franchise,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
              final filter = context
                  .read<LibraryFilterModel>()
                  .filter
                  .add(LibraryFilter(franchises: {franchise}));
              context.pushNamed(
                'games',
                queryParameters: filter.params(),
              );
            },
          ),
        for (final tag in tagsModel.userTags.byGameId(tags['gameId']))
          TagChip(
            tag,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
              context.pushNamed(
                'games',
                queryParameters: LibraryFilter(tags: {tag.name}).params(),
              );
            },
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
    Key? key,
    this.libraryEntry,
    this.gameEntry,
    this.includeCompanies = false,
    this.includeCollections = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tagsModel = context.watch<GameTagsModel>();
    final tags = extractTags(gameEntry, libraryEntry);

    return SizedBox(
      height: 40.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (includeCompanies) ...[
            for (final company in tags['developers'])
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: DeveloperChip(
                  company,
                  onPressed: () => context.pushNamed(
                    'games',
                    queryParameters:
                        LibraryFilter(developers: {company}).params(),
                  ),
                ),
              ),
            for (final company in tags['publishers'])
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: PublisherChip(
                  company,
                  onPressed: () => context.pushNamed(
                    'games',
                    queryParameters:
                        LibraryFilter(publishers: {company}).params(),
                  ),
                ),
              ),
          ],
          if (includeCollections) ...[
            for (final collection in tags['collections'])
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: CollectionChip(
                  collection,
                  onPressed: () {
                    final filter = context
                        .read<LibraryFilterModel>()
                        .filter
                        .add(LibraryFilter(collections: {collection}));
                    context.pushNamed(
                      'games',
                      queryParameters: filter.params(),
                    );
                  },
                ),
              ),
            for (final franchise in tags['franchises'])
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: FranchiseChip(
                  franchise,
                  onPressed: () {
                    final filter = context
                        .read<LibraryFilterModel>()
                        .filter
                        .add(LibraryFilter(franchises: {franchise}));
                    context.pushNamed(
                      'games',
                      queryParameters: filter.params(),
                    );
                  },
                ),
              ),
          ],
          for (final tag in tagsModel.userTags.byGameId(tags['gameId']))
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: TagChip(
                tag,
                onPressed: () => context.pushNamed(
                  'games',
                  queryParameters: LibraryFilter(tags: {tag.name}).params(),
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
  const GameChipsFilter(this.filter, {Key? key}) : super(key: key);

  final LibraryFilter filter;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      for (final store in filter.stores) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: StoreChip(
            store,
            onDeleted: () {
              final filter = context
                  .read<LibraryFilterModel>()
                  .filter
                  .remove(LibraryFilter(stores: {store}));
              context.pushNamed(
                'games',
                queryParameters: filter.params(),
              );
            },
          ),
        ),
      ],
      for (final company in filter.developers) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: DeveloperChip(
            company,
            onDeleted: () {
              final filter = context
                  .read<LibraryFilterModel>()
                  .filter
                  .remove(LibraryFilter(developers: {company}));
              context.pushNamed(
                'games',
                queryParameters: filter.params(),
              );
            },
          ),
        ),
      ],
      for (final company in filter.publishers) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: PublisherChip(
            company,
            onDeleted: () {
              final filter = context
                  .read<LibraryFilterModel>()
                  .filter
                  .remove(LibraryFilter(publishers: {company}));
              context.pushNamed(
                'games',
                queryParameters: filter.params(),
              );
            },
          ),
        ),
      ],
      for (final collection in filter.collections) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: CollectionChip(
            collection,
            onDeleted: () {
              final filter = context
                  .read<LibraryFilterModel>()
                  .filter
                  .remove(LibraryFilter(collections: {collection}));
              context.pushNamed(
                'games',
                queryParameters: filter.params(),
              );
            },
          ),
        ),
      ],
      for (final franchise in filter.franchises) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: FranchiseChip(
            franchise,
            onDeleted: () {
              final filter = context
                  .read<LibraryFilterModel>()
                  .filter
                  .remove(LibraryFilter(franchises: {franchise}));
              context.pushNamed(
                'games',
                queryParameters: filter.params(),
              );
            },
          ),
        ),
      ],
      for (final keyword in filter.keywords) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: KeywordChip(
            keyword,
            onDeleted: () {
              final filter = context
                  .read<LibraryFilterModel>()
                  .filter
                  .remove(LibraryFilter(keywords: {keyword}));
              context.pushNamed(
                'games',
                queryParameters: filter.params(),
              );
            },
          ),
        ),
      ],
      for (final tag in filter.tags) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: TagChip(
            context.read<GameTagsModel>().userTags.get(tag),
            onDeleted: () {
              final filter = context
                  .read<LibraryFilterModel>()
                  .filter
                  .remove(LibraryFilter(tags: {tag}));
              context.pushNamed(
                'games',
                queryParameters: filter.params(),
              );
            },
          ),
        ),
      ],
    ]);
  }
}
