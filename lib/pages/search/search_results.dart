import 'package:espy/modules/documents/user_annotations.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/pages/espy_navigator.dart';
import 'package:espy/widgets/gametags/espy_chips.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TagSearchResults extends StatelessWidget {
  const TagSearchResults(
    this.stores,
    this.developers,
    this.publishers,
    this.collections,
    this.franchises,
    this.genres, {
    super.key,
    this.manualGenres = const [],
    this.userTags = const [],
  });

  final Iterable<String> stores;
  final Iterable<String> developers;
  final Iterable<String> publishers;
  final Iterable<String> collections;
  final Iterable<String> franchises;
  final Iterable<String> genres;
  final Iterable<Genre> manualGenres;
  final Iterable<String> userTags;

  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList(
      itemExtent: 90.0,
      delegate: SliverChildListDelegate(
        [
          if (stores.isNotEmpty)
            _ChipResults(
              title: 'Stores',
              color: StoreChip.color,
              chips: stores.map(
                (store) => StoreChip(
                  store,
                  onPressed: () =>
                      updateLibraryView(context, LibraryFilter(store: store)),
                ),
              ),
            ),
          if (developers.isNotEmpty)
            _ChipResults(
              title: 'Developers',
              color: DeveloperChip.color,
              chips: developers.map(
                (company) => DeveloperChip(
                  company,
                  onPressed: () => context
                      .pushNamed('company', pathParameters: {'name': company}),
                ),
              ),
            ),
          if (publishers.isNotEmpty)
            _ChipResults(
              title: 'Publishers',
              color: PublisherChip.color,
              chips: publishers.map(
                (company) => PublisherChip(
                  company,
                  onPressed: () => context
                      .pushNamed('company', pathParameters: {'name': company}),
                ),
              ),
            ),
          if (collections.isNotEmpty)
            _ChipResults(
              title: 'Collections',
              color: CollectionChip.color,
              chips: collections.map(
                (collection) => CollectionChip(
                  collection,
                  onPressed: () => context.pushNamed('collection',
                      pathParameters: {'name': collection}),
                ),
              ),
            ),
          if (franchises.isNotEmpty)
            _ChipResults(
              title: 'Franchises',
              color: FranchiseChip.color,
              chips: franchises.map(
                (franchise) => FranchiseChip(
                  franchise,
                  onPressed: () => context.pushNamed('collection',
                      pathParameters: {'name': franchise}),
                ),
              ),
            ),
          if (genres.isNotEmpty)
            _ChipResults(
              title: 'Genres',
              color: EspyGenreChip.color,
              chips: genres.map(
                (genre) => EspyGenreChip(
                  genre,
                  onPressed: () =>
                      updateLibraryView(context, LibraryFilter(genre: genre)),
                ),
              ),
            ),
          // if (manualGenres.isNotEmpty)
          //   _ChipResults(
          //     title: 'User Genres',
          //     color: ManualGenreChip.color,
          //     chips: manualGenres.map(
          //       (genreTag) => ManualGenreChip(
          //         genreTag.label,
          //         onPressed: () => updateLibraryView(
          //             context, LibraryFilter(manualGenre: genreTag.encode())),
          //       ),
          //     ),
          //   ),
          // if (userTags.isNotEmpty)
          //   _ChipResults(
          //     title: 'Tags',
          //     color: ManualTagChip.color,
          //     chips: userTags.map(
          //       (tag) => ManualTagChip(
          //         tag,
          //         onPressed: () =>
          //             updateLibraryView(context, LibraryFilter(userTag: tag)),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
}

class _ChipResults extends StatelessWidget {
  const _ChipResults({
    required this.title,
    required this.chips,
    this.color,
  });

  final String title;
  final Iterable<EspyChip> chips;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Results for ',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.0,
                  color: color,
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 40,
              child: ListView(
                primary: true,
                scrollDirection: Axis.horizontal,
                children: [
                  for (final chip in chips)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: chip,
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
