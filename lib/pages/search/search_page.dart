import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_index_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/pages/search/search_results.dart';
import 'package:espy/pages/search/search_text_field.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    final ngrams = _text.toLowerCase().split(' ');
    final libraryModel = context.watch<UserLibraryModel>();
    final tagsModel = context.watch<GameTagsModel>();

    final titleMatches = _text.isNotEmpty
        ? libraryModel.entries
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
        searchBox(),
        TagSearchResults(
          tagsModel.stores.filter(ngrams),
          tagsModel.developers.filter(ngrams),
          tagsModel.publishers.filter(ngrams),
          tagsModel.collections.filter(ngrams),
          tagsModel.franchises.filter(ngrams),
          tagsModel.genres.filter(ngrams),
          manualGenres: tagsModel.manualGenres.filter(ngrams),
          userTags: tagsModel.userTags.filter(ngrams),
        ),
        for (final company in tagsModel.developers.filterExact(ngrams)) ...[
          TileShelve(
            title: company,
            entries: tagsModel.developers.games(company),
            filter: LibraryFilter(developers: {company}),
            color: DeveloperChip.color,
          ),
        ],
        for (final company in tagsModel.publishers.filterExact(ngrams)) ...[
          TileShelve(
            title: company,
            entries: tagsModel.publishers.games(company),
            filter: LibraryFilter(publishers: {company}),
            color: PublisherChip.color,
          ),
        ],
        for (final collection in tagsModel.collections.filterExact(ngrams)) ...[
          TileShelve(
            title: collection,
            entries: tagsModel.collections.games(collection),
            filter: LibraryFilter(collections: {collection}),
            color: CollectionChip.color,
          ),
        ],
        for (final franchise in tagsModel.franchises.filterExact(ngrams)) ...[
          TileShelve(
            title: franchise,
            entries: tagsModel.franchises.games(franchise),
            filter: LibraryFilter(franchises: {franchise}),
            color: FranchiseChip.color,
          ),
        ],
        for (final genre in tagsModel.genres.filterExact(ngrams)) ...[
          TileShelve(
            title: genre,
            entries: tagsModel.genres.games(genre),
            filter: LibraryFilter(genres: {genre}),
            color: EspyGenreTagChip.color,
          ),
        ],
        // for (final genreTag in tagsModel.genreTags.filterExact(ngrams)) ...[
        //   TileShelve(
        //     title: genreTag.name,
        //     entries: tagsModel.genreTags.games(genreTag.name),
        //     filter: LibraryFilter(genreTags: {genreTag.encode()}),
        //     color: GenreTagChip.color,
        //   ),
        // ],
        for (final userTag in tagsModel.userTags.filterExact(ngrams)) ...[
          TileShelve(
            title: userTag,
            entries: tagsModel.manualGenres.games(userTag),
            filter: LibraryFilter(userTags: {userTag}),
            color: TagChip.color,
          ),
        ],
        if (titleMatches.isNotEmpty)
          TileShelve(
            title: 'Title Matches',
            entries: titleMatches,
          ),
        if (_remoteGames.isNotEmpty) ...[
          TileShelve(
            title: 'Not in Library',
            entries: _remoteGames,
          ),
        ],
        if (_fetchingRemoteGames)
          const SliverToBoxAdapter(
            child: Center(child: LinearProgressIndicator()),
          ),
      ],
    );
  }

  Widget searchBox() {
    final isMobile = AppConfigModel.isMobile(context);
    return SliverToBoxAdapter(
      child: SizedBox(
        height: isMobile ? 200 : 120,
        child: Padding(
          padding: isMobile
              ? const EdgeInsets.only(top: 72, left: 16, right: 16)
              : const EdgeInsets.all(16.0),
          child: SearchTextField(
            onChanged: (text) {
              text.toLowerCase().split(' ');
              setState(() {
                _remoteGames.clear();
                _text = text;
              });
            },
            onSubmitted: (text) async {
              setState(() {
                _fetchingRemoteGames = true;
              });
              final remoteGames =
                  await context.read<UserLibraryModel>().searchByTitle(text);
              setState(() {
                _fetchingRemoteGames = false;
                _remoteGames = remoteGames
                    .where((gameEntry) =>
                        context
                            .read<LibraryIndexModel>()
                            .getEntryById(gameEntry.id) ==
                        null)
                    .map((gameEntry) => LibraryEntry.fromGameEntry(gameEntry))
                    .toList();
              });
            },
          ),
        ),
      ),
    );
  }

  String _text = '';
  bool _fetchingRemoteGames = false;
  List<LibraryEntry> _remoteGames = [];
}
