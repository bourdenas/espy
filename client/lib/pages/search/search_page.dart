import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/pages/search/search_results.dart';
import 'package:espy/pages/search/search_text_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    final ngrams = _text.toLowerCase().split(' ');

    final storeMatches =
        context.read<GameTagsModel>().filterStores(ngrams).toList();
    final userTagMatches =
        context.read<GameTagsModel>().filterTags(ngrams).toList();
    final companyMatches =
        context.read<GameTagsModel>().filterCompanies(ngrams).toList();
    final collectionMatches =
        context.read<GameTagsModel>().filterCollections(ngrams).toList();
    final titleMatches = _text.isNotEmpty
        ? context
            .read<GameLibraryModel>()
            .entries
            .where((entry) => ngrams.every((term) => entry.name
                .toLowerCase()
                .split(' ')
                .any((word) => word.startsWith(term))))
            .toList()
        : <LibraryEntry>[];

    return CustomScrollView(
      primary: true,
      shrinkWrap: true,
      slivers: [
        SliverPersistentHeader(
          delegate: searchBox(),
        ),
        if (_text.length < 3)
          TagSearchResults(
            storeMatches,
            userTagMatches,
            companyMatches,
            collectionMatches,
          ),
        if (_text.length >= 3) ...[
          for (final company in companyMatches) ...[
            SliverPersistentHeader(
              pinned: true,
              floating: true,
              delegate: section(context, company, Colors.redAccent,
                  LibraryFilter(companies: {company})),
            ),
            GameSearchResults(
                entries: context
                    .read<GameEntriesModel>()
                    .getEntries(filter: LibraryFilter(companies: {company}))),
          ],
          for (final collection in collectionMatches) ...[
            SliverPersistentHeader(
              pinned: true,
              floating: true,
              delegate: section(context, collection, Colors.indigoAccent,
                  LibraryFilter(collections: {collection})),
            ),
            GameSearchResults(
                entries: context.read<GameEntriesModel>().getEntries(
                    filter: LibraryFilter(collections: {collection}))),
          ],
          for (final tag in userTagMatches) ...[
            SliverPersistentHeader(
              pinned: true,
              floating: true,
              delegate: section(
                  context, tag, Colors.blueGrey, LibraryFilter(tags: {tag})),
            ),
            GameSearchResults(
                entries: context
                    .read<GameEntriesModel>()
                    .getEntries(filter: LibraryFilter(tags: {tag}))),
          ],
        ],
        if (titleMatches.isNotEmpty) ...[
          SliverPersistentHeader(
            pinned: true,
            floating: true,
            delegate: section(context, 'Title Matches', Colors.grey),
          ),
          GameSearchResults(entries: titleMatches),
        ],
      ],
    );
  }

  _SectionHeader section(BuildContext context, String title, Color color,
      [LibraryFilter? filter]) {
    return _SectionHeader(
      minHeight: 50.0,
      maxHeight: 50.0,
      child: Material(
        elevation: 10.0,
        color: Color.fromARGB(255, 72, 72, 72),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(Icons.arrow_drop_down),
              Text(
                'Results for ',
                style: TextStyle(
                  fontSize: 16.0,
                ),
              ),
              TextButton(
                onPressed: filter != null
                    ? () =>
                        context.pushNamed('games', queryParams: filter.params())
                    : null,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: color,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _SectionHeader searchBox() {
    return _SectionHeader(
      minHeight: 80.0,
      maxHeight: 120.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SearchTextField(
          onChanged: (text) {
            text.toLowerCase().split(' ');
            setState(() {
              _text = text;
            });
          },
        ),
      ),
    );
  }

  String _text = '';
}

class _SectionHeader extends SliverPersistentHeaderDelegate {
  _SectionHeader({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(_SectionHeader oldSearchBar) {
    return maxHeight != oldSearchBar.maxHeight ||
        minHeight != oldSearchBar.minHeight ||
        child != oldSearchBar.child;
  }
}
