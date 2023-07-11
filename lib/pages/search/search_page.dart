import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/library_entries_model.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/search/search_results.dart';
import 'package:espy/pages/search/search_text_field.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:espy/widgets/tiles/tile_shelve.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    final ngrams = _text.toLowerCase().split(' ');
    final gameEntriesModel = context.watch<LibraryEntriesModel>();
    final tagsModel = context.watch<GameTagsModel>();

    final titleMatches = _text.isNotEmpty
        ? gameEntriesModel
            .filter(LibraryFilter(view: LibraryView.all))
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
          tagsModel.userTags.filter(ngrams),
          tagsModel.developers.filter(ngrams),
          tagsModel.publishers.filter(ngrams),
          tagsModel.collections.filter(ngrams),
          tagsModel.franchises.filter(ngrams),
          tagsModel.genres.filter(ngrams),
          tagsModel.genreTags.filter(ngrams),
          tagsModel.keywords.filter(ngrams),
        ),
        for (final company in tagsModel.developers.filterExact(ngrams)) ...[
          TileShelve(
            title: company,
            color: DeveloperChip.color,
            filter: LibraryFilter(developers: {company}),
          ),
        ],
        for (final company in tagsModel.publishers.filterExact(ngrams)) ...[
          TileShelve(
            title: company,
            color: PublisherChip.color,
            filter: LibraryFilter(publishers: {company}),
          ),
        ],
        for (final collection in tagsModel.collections.filterExact(ngrams)) ...[
          TileShelve(
            title: collection,
            color: CollectionChip.color,
            filter: LibraryFilter(collections: {collection}),
          ),
        ],
        for (final franchise in tagsModel.franchises.filterExact(ngrams)) ...[
          TileShelve(
            title: franchise,
            color: FranchiseChip.color,
            filter: LibraryFilter(franchises: {franchise}),
          ),
        ],
        for (final genre in tagsModel.genres.filterExact(ngrams)) ...[
          TileShelve(
            title: genre,
            color: GenreChip.color,
            filter: LibraryFilter(genres: {genre}),
          ),
        ],
        for (final genreTag in tagsModel.genreTags.filterExact(ngrams)) ...[
          TileShelve(
            title: genreTag.name,
            color: GenreTagChip.color,
            filter: LibraryFilter(genreTags: {genreTag.encode()}),
          ),
        ],
        for (final tag in tagsModel.userTags.filterExact(ngrams)) ...[
          TileShelve(
            title: tag.name,
            color: Colors.blueGrey,
            filter: LibraryFilter(tags: {tag.name}),
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
                            .read<LibraryEntriesModel>()
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
