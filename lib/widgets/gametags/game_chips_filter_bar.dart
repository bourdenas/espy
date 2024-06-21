import 'package:espy/modules/documents/user_annotations.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/espy_navigator.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameChipsFilterBar extends StatelessWidget {
  const GameChipsFilterBar(this.filter, {super.key});

  final LibraryFilter filter;

  @override
  Widget build(BuildContext context) {
    void onRemove(LibraryFilter filter) {
      final updatedFilter =
          context.read<LibraryFilterModel>().filter.remove(filter);
      updateLibraryView(context, updatedFilter);
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
      // for (final genre in filter.genres) ...[
      //   Padding(
      //     padding: const EdgeInsets.all(4.0),
      //     child: EspyGenreTagChip(
      //       genre,
      //       onDeleted: () => onRemove(LibraryFilter(genres: {genre})),
      //     ),
      //   ),
      // ],
      for (final genreTag in filter.manualGenres) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: ManualGenreChip(
            Genre.decode(genreTag).label,
            onDeleted: () => onRemove(LibraryFilter(manualGenres: {genreTag})),
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
      for (final userTag in filter.userTags) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: TagChip(
            userTag,
            onDeleted: () => onRemove(LibraryFilter(userTags: {userTag})),
          ),
        ),
      ],
    ]);
  }
}
