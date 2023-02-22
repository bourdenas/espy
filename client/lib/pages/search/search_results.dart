import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/pages/gamelist/game_grid_card.dart';
import 'package:espy/pages/gamelist/game_list_card.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/src/provider.dart';

class GameSearchResults extends StatelessWidget {
  const GameSearchResults({
    Key? key,
    required this.entries,
    this.cardWidth,
    this.cardAspectRatio,
  }) : super(key: key);

  final Iterable<LibraryEntry> entries;
  final double? cardWidth;
  final double? cardAspectRatio;

  @override
  Widget build(BuildContext context) {
    return context.watch<AppConfigModel>().libraryLayout == LibraryLayout.GRID
        ? gridView(entries)
        : listView(entries);
  }

  SliverGrid gridView(Iterable<LibraryEntry> matchedEntries) {
    return SliverGrid.extent(
      maxCrossAxisExtent: cardWidth ?? 200,
      childAspectRatio: cardAspectRatio ?? .75,
      children: matchedEntries.map((e) => GameGridCard(entry: e)).toList(),
    );
  }

  SliverGrid listView(Iterable<LibraryEntry> matchedEntries) {
    return SliverGrid.extent(
      maxCrossAxisExtent: cardWidth ?? 600.0,
      childAspectRatio: cardAspectRatio ?? 2.5,
      children: matchedEntries.map((e) => GameListCard(entry: e)).toList(),
    );
  }
}

class TagSearchResults extends StatelessWidget {
  const TagSearchResults(
    this.stores,
    this.userTags,
    this.companies,
    this.collections, {
    Key? key,
  }) : super(key: key);

  final Iterable<String> stores;
  final Iterable<UserTag> userTags;
  final Iterable<String> companies;
  final Iterable<String> collections;

  @override
  Widget build(BuildContext context) {
    return SliverFixedExtentList(
      itemExtent: 90.0,
      delegate: SliverChildListDelegate(
        [
          if (stores.isNotEmpty)
            _ChipResults(
              title: 'Stores',
              color: Colors.deepPurpleAccent,
              chips: stores.map(
                (store) => StoreChip(
                  store,
                  onPressed: () => context.pushNamed(
                    'games',
                    queryParams: LibraryFilter(stores: {store}).params(),
                  ),
                ),
              ),
            ),
          if (companies.isNotEmpty)
            _ChipResults(
              title: 'Companies',
              color: Colors.redAccent,
              chips: companies.map(
                (company) => CompanyChip(
                  company,
                  onPressed: () => context.pushNamed(
                    'games',
                    queryParams: LibraryFilter(companies: {company}).params(),
                  ),
                ),
              ),
            ),
          if (collections.isNotEmpty)
            _ChipResults(
              title: 'Collections',
              color: Colors.indigoAccent,
              chips: collections.map(
                (collection) => CollectionChip(
                  collection,
                  onPressed: () => context.pushNamed(
                    'games',
                    queryParams:
                        LibraryFilter(collections: {collection}).params(),
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
                  onPressed: () => context.pushNamed(
                    'games',
                    queryParams: LibraryFilter(tags: {tag.name}).params(),
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

Map<Color, List<UserTag>> groupTags(Iterable<UserTag> tags) {
  var groups = <Color, List<UserTag>>{};
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
