import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameTags extends StatelessWidget {
  final GameEntry gameEntry;

  const GameTags({Key? key, required this.gameEntry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GameChipsWrap(gameEntry),
      ],
    );
  }
}

class _GameChipsWrap extends StatelessWidget {
  final GameEntry gameEntry;

  const _GameChipsWrap(this.gameEntry);

  @override
  Widget build(BuildContext context) {
    final tagsModel = context.watch<GameTagsModel>();

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        for (final company in gameEntry.developers.map((e) => e.name))
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
        for (final company in gameEntry.publishers.map((e) => e.name))
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
        for (final collection in gameEntry.collections.map((e) => e.name))
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
        for (final franchise in gameEntry.franchises.map((e) => e.name))
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
        for (final genre in tagsModel.filterEspyGenres(gameEntry.genres))
          GenreChip(
            genre,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
              final filter = context
                  .read<LibraryFilterModel>()
                  .filter
                  .add(LibraryFilter(genres: {genre}));
              context.pushNamed(
                'games',
                queryParameters: filter.params(),
              );
            },
          ),
        for (final genreTag in tagsModel.genreTags.byGameId(gameEntry.id))
          GenreChip(
            genreTag.name,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
              final filter = context
                  .read<LibraryFilterModel>()
                  .filter
                  .add(LibraryFilter(genreTags: {genreTag.encode()}));
              context.pushNamed(
                'games',
                queryParameters: filter.params(),
              );
            },
          ),
        for (final tag in tagsModel.userTags.byGameId(gameEntry.id))
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
                .remove(tag, gameEntry.id),
            onRightClick: () =>
                context.read<GameTagsModel>().userTags.moveCluster(tag),
          ),
      ],
    );
  }
}

class GameCardChips extends StatelessWidget {
  final LibraryEntry libraryEntry;
  final bool includeCompanies;
  final bool includeCollections;

  const GameCardChips({
    Key? key,
    required this.libraryEntry,
    this.includeCompanies = false,
    this.includeCollections = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tagsModel = context.watch<GameTagsModel>();

    return SizedBox(
      height: 40.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (includeCompanies) ...[
            for (final company in libraryEntry.developers)
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
            for (final company in libraryEntry.publishers)
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
            for (final collection in libraryEntry.collections)
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
            for (final franchise in libraryEntry.franchises)
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
          for (final genre in libraryEntry.digest.genres)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: GenreChip(
                genre,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                  final filter = context
                      .read<LibraryFilterModel>()
                      .filter
                      .add(LibraryFilter(genres: {genre}));
                  context.pushNamed(
                    'games',
                    queryParameters: filter.params(),
                  );
                },
              ),
            ),
          for (final genreTag in tagsModel.genreTags.byGameId(libraryEntry.id))
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: GenreChip(
                genreTag.name,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                  final filter = context
                      .read<LibraryFilterModel>()
                      .filter
                      .add(LibraryFilter(genreTags: {genreTag.encode()}));
                  context.pushNamed(
                    'games',
                    queryParameters: filter.params(),
                  );
                },
              ),
            ),
          for (final tag in tagsModel.userTags.byGameId(libraryEntry.id))
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
                    .remove(tag, libraryEntry.id),
                onRightClick: () =>
                    context.read<GameTagsModel>().userTags.moveCluster(tag),
              ),
            ),
        ],
      ),
    );
  }
}
