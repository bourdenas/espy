import 'dart:async';

import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/pages/search/search_results.dart';
import 'package:espy/pages/search/search_text_field.dart';
import 'package:espy/widgets/library/library_group.dart';
import 'package:espy/widgets/library/library_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    final ngrams = _text.toLowerCase().split(' ');
    final gameEntriesModel = context.watch<GameEntriesModel>();
    final tagsModel = context.watch<GameTagsModel>();

    final titleMatches = _text.isNotEmpty
        ? gameEntriesModel
            .getEntries()
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
          LibraryGroup(
            title: company,
            color: Colors.redAccent,
            filter: LibraryFilter(companies: {company}),
          ),
        ],
        for (final collection in tagsModel.filterCollectionsExact(ngrams)) ...[
          LibraryGroup(
            title: collection,
            color: Colors.indigoAccent,
            filter: LibraryFilter(collections: {collection}),
          ),
        ],
        for (final tag in tagsModel.filterTagsExact(ngrams)) ...[
          LibraryGroup(
            title: tag.name,
            color: Colors.blueGrey,
            filter: LibraryFilter(tags: {tag.name}),
          ),
        ],
        if (titleMatches.isNotEmpty)
          LibraryGroup(
            title: 'Title Matches',
            color: Colors.grey,
            entries: titleMatches,
          ),
        if (_remoteGames.isNotEmpty) ...[
          LibraryGroup(
            title: 'Not in Library',
            color: Colors.grey,
            entries: _remoteGames,
          ),
        ],
      ],
    );
  }

  LibraryHeaderDelegate searchBox() {
    final isMobile = AppConfigModel.isMobile(context);
    return LibraryHeaderDelegate(
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
                _remoteGames = remoteGames
                    .where((gameEntry) =>
                        context
                            .read<GameEntriesModel>()
                            .getEntryById(gameEntry.id) ==
                        null)
                    .map((gameEntry) => LibraryEntry.fromGameEntry(gameEntry))
                    .toList();
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
  List<LibraryEntry> _remoteGames = [];
}
