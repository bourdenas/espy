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
    void onRemove(LibraryFilter filter) {
      final updatedFilter =
          context.read<LibraryFilterModel>().filter.remove(filter);
      context.pushNamed(
        'games',
        queryParameters: updatedFilter.params(),
      );
    }

    return Row(children: [
      for (final store in filter.stores) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: StoreChip(
            store,
            onDeleted: () => onRemove(LibraryFilter(stores: {store})),
          ),
        ),
      ],
      for (final company in filter.developers) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: DeveloperChip(
            company,
            onDeleted: () => onRemove(LibraryFilter(developers: {company})),
          ),
        ),
      ],
      for (final company in filter.publishers) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: PublisherChip(
            company,
            onDeleted: () => onRemove(LibraryFilter(publishers: {company})),
          ),
        ),
      ],
      for (final collection in filter.collections) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: CollectionChip(
            collection,
            onDeleted: () => onRemove(LibraryFilter(collections: {collection})),
          ),
        ),
      ],
      for (final franchise in filter.franchises) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: FranchiseChip(
            franchise,
            onDeleted: () => onRemove(LibraryFilter(franchises: {franchise})),
          ),
        ),
      ],
      for (final genre in filter.genres) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: GenreChip(
            genre,
            onDeleted: () => onRemove(LibraryFilter(genres: {genre})),
          ),
        ),
      ],
      for (final genreTag in filter.genreTags) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: GenreTagChip(
            Genre.decode(genreTag).name,
            onDeleted: () => onRemove(LibraryFilter(genreTags: {genreTag})),
          ),
        ),
      ],
      for (final keyword in filter.keywords) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: KeywordChip(
            keyword,
            onDeleted: () => onRemove(LibraryFilter(keywords: {keyword})),
          ),
        ),
      ],
      for (final tag in filter.tags) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: TagChip(
            context.read<GameTagsModel>().userTags.get(tag),
            onDeleted: () => onRemove(LibraryFilter(tags: {tag})),
          ),
        ),
      ],
    ]);
  }
}
