import 'package:espy/modules/documents/user_tags.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class GameChipsFilterBar extends StatelessWidget {
  const GameChipsFilterBar(this.filter, {Key? key}) : super(key: key);

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
      for (final genre in filter.genres) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: GenreChip(
            genre,
            onDeleted: () {
              final filter = context
                  .read<LibraryFilterModel>()
                  .filter
                  .remove(LibraryFilter(genres: {genre}));
              context.pushNamed(
                'games',
                queryParameters: filter.params(),
              );
            },
          ),
        ),
      ],
      for (final genreTag in filter.genreTags) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: GenreTagChip(
            Genre.decode(genreTag).name,
            onDeleted: () {
              final filter = context
                  .read<LibraryFilterModel>()
                  .filter
                  .remove(LibraryFilter(genreTags: {genreTag}));
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
