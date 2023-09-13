import 'package:espy/modules/documents/user_tags.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/tags/user_tag_manager.dart';
import 'package:espy/pages/espy_navigator.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TagSearchResults extends StatelessWidget {
  const TagSearchResults(
    this.stores,
    this.userTags,
    this.developers,
    this.publishers,
    this.collections,
    this.franchises,
    this.genres,
    this.genresTags,
    this.keywords, {
    Key? key,
  }) : super(key: key);

  final Iterable<String> stores;
  final Iterable<CustomUserTag> userTags;
  final Iterable<String> developers;
  final Iterable<String> publishers;
  final Iterable<String> collections;
  final Iterable<String> franchises;
  final Iterable<String> genres;
  final Iterable<Genre> genresTags;
  final Iterable<String> keywords;

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
                  onPressed: () => updateLibraryView(
                      context, LibraryFilter(stores: {store})),
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
                  onPressed: () => updateLibraryView(
                      context, LibraryFilter(developers: {company})),
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
                  onPressed: () => updateLibraryView(
                      context, LibraryFilter(publishers: {company})),
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
                  onPressed: () => updateLibraryView(
                      context, LibraryFilter(collections: {collection})),
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
                  onPressed: () => updateLibraryView(
                    context,
                    LibraryFilter(franchises: {franchise}),
                  ),
                ),
              ),
            ),
          if (genres.isNotEmpty)
            _ChipResults(
              title: 'Genres',
              color: GenreChip.color,
              chips: genres.map(
                (genre) => GenreChip(
                  genre,
                  onPressed: () => updateLibraryView(
                    context,
                    LibraryFilter(genres: {genre}),
                  ),
                ),
              ),
            ),
          if (genresTags.isNotEmpty)
            _ChipResults(
              title: 'Genres',
              color: GenreTagChip.color,
              chips: genresTags.map(
                (genreTag) => GenreTagChip(
                  genreTag.name,
                  onPressed: () => updateLibraryView(
                    context,
                    LibraryFilter(genreTags: {genreTag.encode()}),
                  ),
                ),
              ),
            ),
          if (keywords.isNotEmpty)
            _ChipResults(
              title: 'Keywords',
              color: KeywordChip.color,
              chips: keywords.map(
                (keyword) => KeywordChip(
                  keyword,
                  onPressed: () => updateLibraryView(
                    context,
                    LibraryFilter(keywords: {keyword}),
                  ),
                ),
              ),
            ),
          for (final group in groupTags(userTags).entries)
            _ChipResults(
              title: 'Tags',
              color: group.key,
              chips: group.value.map(
                (tag) => TagChip(
                  tag,
                  onPressed: () => updateLibraryView(
                    context,
                    LibraryFilter(tags: {tag.name}),
                  ),
                  onRightClick: () =>
                      context.read<GameTagsModel>().userTags.moveCluster(tag),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Map<Color, List<CustomUserTag>> groupTags(Iterable<CustomUserTag> tags) {
  var groups = <Color, List<CustomUserTag>>{};
  for (final tag in tags) {
    (groups[tag.color] ??= []).add(tag);
  }
  return groups;
}

class _ChipResults extends StatelessWidget {
  const _ChipResults({
    Key? key,
    required this.title,
    required this.chips,
    this.color,
  }) : super(key: key);

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
