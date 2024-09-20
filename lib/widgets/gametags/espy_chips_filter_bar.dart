import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/widgets/gametags/espy_chips.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EspyChipsFilterBar extends StatelessWidget {
  const EspyChipsFilterBar(this.filter, {super.key});

  final LibraryFilter filter;

  @override
  Widget build(BuildContext context) {
    void onRemove(LibraryFilter filter) {
      final updatedFilter =
          context.read<LibraryFilterModel>().filter.subtract(filter);
      context.read<LibraryFilterModel>().filter = updatedFilter;
    }

    return Row(children: [
      if (filter.store != null) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: StoreChip(
            filter.store!,
            onDeleted: () => onRemove(LibraryFilter(store: filter.store)),
          ),
        ),
      ],
      if (filter.developer != null) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: DeveloperChip(
            filter.developer!,
            onDeleted: () =>
                onRemove(LibraryFilter(developer: filter.developer)),
          ),
        ),
      ],
      if (filter.publisher != null) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: PublisherChip(
            filter.publisher!,
            onDeleted: () =>
                onRemove(LibraryFilter(publisher: filter.publisher)),
          ),
        ),
      ],
      if (filter.collection != null) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: CollectionChip(
            filter.collection!,
            onDeleted: () =>
                onRemove(LibraryFilter(collection: filter.collection)),
          ),
        ),
      ],
      if (filter.franchise != null) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: FranchiseChip(
            filter.franchise!,
            onDeleted: () =>
                onRemove(LibraryFilter(franchise: filter.franchise)),
          ),
        ),
      ],
      if (filter.genreGroup != null && filter.genre == null) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: GenreGroupChip(
            filter.genreGroup!,
            onDeleted: () =>
                onRemove(LibraryFilter(genreGroup: filter.genreGroup)),
          ),
        ),
      ],
      if (filter.genre != null) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: EspyGenreChip(
            filter.genre!,
            onDeleted: () => onRemove(LibraryFilter(genre: filter.genre)),
          ),
        ),
      ],
      // if (filter.manualGenre != null) ...[
      //   Padding(
      //     padding: const EdgeInsets.all(4.0),
      //     child: ManualGenreChip(
      //       filter.Genre!.decode(genreTag).label,
      //       onDeleted: () =>
      //           onRemove(LibraryFilter(manualGenre: filter.genreTag)),
      //     ),
      //   ),
      // ],
      if (filter.keyword != null) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: KeywordChip(
            filter.keyword!,
            onDeleted: () => onRemove(LibraryFilter(keyword: filter.keyword)),
          ),
        ),
      ],
      if (filter.userTag != null) ...[
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: ManualTagChip(
            filter.userTag!,
            onDeleted: () => onRemove(LibraryFilter(userTag: filter.userTag)),
          ),
        ),
      ],
    ]);
  }
}
