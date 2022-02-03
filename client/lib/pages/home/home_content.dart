import 'package:espy/constants/urls.dart';
import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/documents/annotation.dart';
import 'package:espy/modules/models/app_config_model.dart';
import 'package:espy/modules/models/game_entries_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/modules/models/unmatched_library_model.dart';
import 'package:espy/pages/home/home_slate.dart';
import 'package:espy/pages/home/slate_tile.dart';
import 'package:espy/widgets/empty_library.dart';
import 'package:espy/pages/home/home_headline.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = context.watch<GameEntriesModel>().getEntries(null);
    final unmatchedEntries = context.watch<UnmatchedEntriesModel>().entries;

    return Scaffold(
      body: entries.isNotEmpty || unmatchedEntries.isNotEmpty
          ? library(context)
          : EmptyLibrary(),
    );
  }

  Widget library(BuildContext context) {
    final model = context.watch<GameEntriesModel>();
    final appConfig = context.watch<AppConfigModel>();

    _SlateInfo filter(String title, LibraryFilter filter) {
      final entries = model
          .getEntries(filter)
          .take(appConfig.isMobile(context) ? 8 : 32)
          .map(
            (entry) => SlateTileData(
              image: '${Urls.imageProvider}/t_cover_big/${entry.cover}.jpg',
              onTap: () => Navigator.pushNamed(context, '/details',
                  arguments: '${entry.id}'),
            ),
          )
          .toList();
      return _SlateInfo(title: title, filter: filter, entries: entries);
    }

    final filters = [
      filter('GOG', LibraryFilter(stores: {'gog'})),
      filter('Steam', LibraryFilter(stores: {'steam'})),
      filter('EGS', LibraryFilter(stores: {'egs'})),
      filter(
          'Larian', LibraryFilter(companies: {Annotation(name: '', id: 510)})),
    ];

    final unmatchedEntries = context.watch<UnmatchedEntriesModel>().entries;

    return SingleChildScrollView(
      key: Key('libraryScrollView'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (appConfig.isMobile(context))
            HomeHeadline()
          else
            SizedBox(height: 64),
          for (final filter in filters)
            if (filter.entries.isNotEmpty)
              HomeSlate(
                title: filter.title,
                onExpand: () => Navigator.pushNamed(context, '/games',
                    arguments: filter.filter.encode()),
                tiles: filter.entries,
              ),
          if (unmatchedEntries.isNotEmpty)
            HomeSlate(
              title: 'Unmatched Entries',
              onExpand: () => Navigator.pushNamed(context, '/unmatched'),
              tiles: unmatchedEntries
                  .take(appConfig.isMobile(context) ? 8 : 32)
                  .map((entry) => SlateTileData(
                        title: entry.title,
                        image: null,
                        onTap: () => MatchingDialog.show(context, entry),
                      ))
                  .toList(),
            ),
          SizedBox(height: 30.0),
        ],
      ),
    );
  }
}

class _SlateInfo {
  _SlateInfo({
    required this.title,
    required this.filter,
    required this.entries,
  });

  String title;
  LibraryFilter filter;
  List<SlateTileData> entries = [];
}
