import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/pages/gamelist/game_list_card.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class GameSearchResults extends StatelessWidget {
  const GameSearchResults({
    Key? key,
    required this.query,
  }) : super(key: key);

  final String query;

  @override
  Widget build(BuildContext context) {
    final searchTerms = query.toLowerCase().split(' ');
    final matchedEntries = query.isNotEmpty
        ? context
            .read<GameLibraryModel>()
            .entries
            .where((entry) => searchTerms.every((term) => entry.name
                .toLowerCase()
                .split(' ')
                .any((word) => word.startsWith(term))))
            .toList()
        : [];

    return SliverGrid.extent(
      maxCrossAxisExtent: 600.0,
      childAspectRatio: 2.5,
      children: matchedEntries.map((e) => GameListCard(entry: e)).toList(),
    );
  }
}

class TagSearchResults extends StatelessWidget {
  const TagSearchResults({
    Key? key,
    required this.query,
  }) : super(key: key);

  final String query;

  @override
  Widget build(BuildContext context) {
    final searchTerms = query.toLowerCase().split(' ');

    final storeChips = context
        .read<GameTagsModel>()
        .filterStores(searchTerms)
        .map((store) => StoreChip(
              store,
              onPressed: () => Navigator.pushNamed(
                context,
                '/games',
                arguments: LibraryFilter(stores: {store}).encode(),
              ),
            ))
        .toList();
    final tagChips = context
        .read<GameTagsModel>()
        .filterTags(searchTerms)
        .map((tag) => TagChip(
              tag,
              onPressed: () => Navigator.pushNamed(
                context,
                '/games',
                arguments: LibraryFilter(tags: {tag}).encode(),
              ),
            ))
        .toList();
    final companyChips = context
        .read<GameTagsModel>()
        .filterCompanies(searchTerms)
        .map((company) => CompanyChip(
              company,
              onPressed: () => Navigator.pushNamed(
                context,
                '/games',
                arguments: LibraryFilter(companies: {company}).encode(),
              ),
            ))
        .toList();
    final collectionChips = context
        .read<GameTagsModel>()
        .filterCollections(searchTerms)
        .map((collection) => CollectionChip(
              collection,
              onPressed: () => Navigator.pushNamed(
                context,
                '/games',
                arguments: LibraryFilter(collections: {collection}).encode(),
              ),
            ))
        .toList();

    return SliverFixedExtentList(
      itemExtent: 90.0,
      delegate: SliverChildListDelegate(
        [
          if (tagChips.isNotEmpty)
            _ChipResults(
              title: 'Tags',
              color: Colors.blueGrey,
              chips: tagChips,
            ),
          if (storeChips.isNotEmpty)
            _ChipResults(
              title: 'Stores',
              color: Colors.deepPurpleAccent,
              chips: storeChips,
            ),
          if (companyChips.isNotEmpty)
            _ChipResults(
              title: 'Companies',
              color: Colors.redAccent,
              chips: companyChips,
            ),
          if (collectionChips.isNotEmpty)
            _ChipResults(
              title: 'Collections',
              color: Colors.indigoAccent,
              chips: collectionChips,
            ),
        ],
      ),
    );
  }
}

class _ChipResults extends StatelessWidget {
  const _ChipResults({
    Key? key,
    required this.title,
    required this.chips,
    this.color,
  }) : super(key: key);

  final String title;
  final List<EspyChip> chips;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
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
            child: Container(
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
