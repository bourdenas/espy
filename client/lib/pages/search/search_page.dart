import 'dart:async';

import 'package:espy/modules/documents/game_entry.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
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
    final gameEntriesModel = context.read<GameEntriesModel>();
    final tagsModel = context.watch<GameTagsModel>();

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
        TagSearchResults(
          tagsModel.filterStores(ngrams),
          tagsModel.filterTags(ngrams),
          tagsModel.filterCompanies(ngrams),
          tagsModel.filterCollections(ngrams),
        ),
        for (final company in tagsModel.filterCompaniesExact(ngrams)) ...[
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
        for (final collection in tagsModel.filterCollectionsExact(ngrams)) ...[
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
        for (final tag in tagsModel.filterTagsExact(ngrams)) ...[
          SliverPersistentHeader(
            pinned: true,
            floating: true,
            delegate: section(context, tag.name, Colors.blueGrey,
                LibraryFilter(tags: {tag.name})),
          ),
          GameSearchResults(
              entries: context
                  .read<GameEntriesModel>()
                  .getEntries(filter: LibraryFilter(tags: {tag.name}))),
        ],
        if (titleMatches.isNotEmpty) ...[
          SliverPersistentHeader(
            pinned: true,
            floating: true,
            delegate: section(context, 'Title Matches', Colors.grey),
          ),
          GameSearchResults(entries: titleMatches),
        ],
        if (_fetchingRemoteGames || _remoteGames.isNotEmpty) ...[
          SliverPersistentHeader(
            pinned: true,
            floating: true,
            delegate: section(context, 'Not in Library', Colors.grey),
          ),
          if (_fetchingRemoteGames)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          GameSearchResults(
              entries: _remoteGames
                  .where((gameEntry) =>
                      gameEntriesModel.getEntryById(gameEntry.id) == null)
                  .map((gameEntry) => LibraryEntry.fromGameEntry(gameEntry))),
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
        color: AppConfigModel.foregroundColor,
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
    final isMobile = AppConfigModel.isMobile(context);
    return _SectionHeader(
      minHeight: 80.0,
      maxHeight: isMobile ? 200 : 120,
      child: Padding(
        padding: isMobile
            ? const EdgeInsets.only(top: 72, left: 16, right: 16)
            : const EdgeInsets.all(16.0),
        child: SearchTextField(
          onChanged: (text) {
            text.toLowerCase().split(' ');
            setState(() {
              _text = text;
            });

            _remoteGames.clear();
            _timer.cancel();
            _timer = Timer(const Duration(seconds: 1), () async {
              setState(() {
                _fetchingRemoteGames = true;
              });
              final remoteGames =
                  await context.read<GameLibraryModel>().searchByTitle(text);
              setState(() {
                _fetchingRemoteGames = false;
                _remoteGames = remoteGames;
              });
            });
          },
        ),
      ),
    );
  }

  String _text = '';
  Timer _timer = Timer(const Duration(seconds: 0), () {});
  bool _fetchingRemoteGames = false;
  List<GameEntry> _remoteGames = [];
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
