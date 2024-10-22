import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/pages/espy_navigator.dart';
import 'package:espy/widgets/gametags/espy_chips.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Tags shows on a LibraryEntry's grid/list card.
class EspyChipsGameCard extends StatelessWidget {
  final LibraryEntry libraryEntry;
  final bool includeCompanies;
  final bool includeCollections;

  const EspyChipsGameCard({
    super.key,
    required this.libraryEntry,
    this.includeCompanies = false,
    this.includeCollections = true,
  });

  @override
  Widget build(BuildContext context) {
    final tagsModel = context.watch<GameTagsModel>();

    return Column(
      children: [
        SizedBox(
          height: 40.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (includeCompanies) ...[
                for (final company in libraryEntry.developers)
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: DeveloperChip(
                      company,
                      onPressed: () => context.pushNamed('company',
                          pathParameters: {'name': company}),
                    ),
                  ),
                for (final company in libraryEntry.publishers)
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: PublisherChip(
                      company,
                      onPressed: () => context.pushNamed('company',
                          pathParameters: {'name': company}),
                    ),
                  ),
              ],
              if (includeCollections) ...[
                for (final collection in libraryEntry.collections)
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CollectionChip(
                      collection,
                      onPressed: () => addFilter(
                          context, LibraryFilter(collection: collection)),
                    ),
                  ),
                for (final franchise in libraryEntry.franchises)
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: FranchiseChip(
                      franchise,
                      onPressed: () => addFilter(
                          context, LibraryFilter(franchise: franchise)),
                    ),
                  ),
              ],
              for (final genre in libraryEntry.digest.espyGenres)
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: EspyGenreChip(
                    genre,
                    onPressed: () =>
                        addRefinement(context, LibraryFilter(genre: genre)),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 40.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final manualGenre
                  in tagsModel.manualGenres.byGameId(libraryEntry.id))
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ManualGenreChip(
                    manualGenre.label,
                    onPressed: () {},
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

void addFilter(BuildContext context, LibraryFilter filter) {
  final updatedFilter = context.read<LibraryFilterModel>().filter.add(filter);
  updateLibraryView(context, updatedFilter);
}

void addRefinement(BuildContext context, LibraryFilter filter) {
  context.read<RefinementModel>().refinement = filter;
}
