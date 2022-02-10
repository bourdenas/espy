import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class SearchResults extends StatelessWidget {
  const SearchResults({
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
        .map((store) => StoreChip(store))
        .toList();
    final tagChips = context
        .read<GameTagsModel>()
        .filterTags(searchTerms)
        .map((tag) => TagChip(tag))
        .toList();
    final companyChips = context
        .read<GameTagsModel>()
        .filterCompanies(searchTerms)
        .map((company) => CompanyChip(company))
        .toList();
    final collectionChips = context
        .read<GameTagsModel>()
        .filterCollections(searchTerms)
        .map((collection) => CollectionChip(collection))
        .toList();

    return Column(
      children: [
        if (tagChips.isNotEmpty)
          ChipResults(
            title: 'Tags',
            color: Colors.blueGrey,
            chips: tagChips,
          ),
        if (storeChips.isNotEmpty)
          ChipResults(
            title: 'Stores',
            color: Colors.deepPurpleAccent,
            chips: storeChips,
          ),
        if (companyChips.isNotEmpty)
          ChipResults(
            title: 'Companies',
            color: Colors.redAccent,
            chips: companyChips,
          ),
        if (collectionChips.isNotEmpty)
          ChipResults(
            title: 'Collections',
            color: Colors.indigoAccent,
            chips: collectionChips,
          ),
      ],
    );
  }
}

class ChipResults extends StatelessWidget {
  const ChipResults({
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
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Search Result for ',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .headline6
                    ?.copyWith(color: color),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 40,
              child: ListView(
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
