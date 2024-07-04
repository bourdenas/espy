import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/pages/espy_navigator.dart';
import 'package:espy/widgets/gametags/game_chips.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Tags shows on GameEntry's details page.
class GameTags extends StatelessWidget {
  const GameTags(this.libraryEntry, {super.key});

  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
    final tagsModel = context.watch<GameTagsModel>();

    void onChipPressed(LibraryFilter filter) {
      if (context.canPop()) {
        context.pop();
      }
      final updatedFilter =
          context.read<LibraryFilterModel>().filter.add(filter);
      updateLibraryView(context, updatedFilter);
    }

    return Column(
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            for (final company in libraryEntry.developers)
              DeveloperChip(
                company,
                onPressed: () =>
                    onChipPressed(LibraryFilter(developer: company)),
              ),
            for (final company in libraryEntry.publishers)
              PublisherChip(
                company,
                onPressed: () =>
                    onChipPressed(LibraryFilter(publisher: company)),
              ),
            for (final collection in libraryEntry.collections)
              CollectionChip(
                collection,
                onPressed: () =>
                    onChipPressed(LibraryFilter(collection: collection)),
              ),
            for (final franchise in libraryEntry.franchises)
              FranchiseChip(
                franchise,
                onPressed: () =>
                    onChipPressed(LibraryFilter(franchise: franchise)),
              ),
            for (final genre in libraryEntry.digest.espyGenres)
              EspyGenreChip(
                genre,
                onPressed: () =>
                    onChipPressed(LibraryFilter(manualGenre: genre)),
              ),
            if (context.watch<UserModel>().isSignedIn)
              for (final tag
                  in tagsModel.userTags.tagsByGameId(libraryEntry.id))
                TagChip(
                  tag,
                  onPressed: () => onChipPressed(LibraryFilter(userTag: tag)),
                ),
            if (context.watch<UserModel>().isSignedIn)
              for (final manualGenre
                  in tagsModel.manualGenres.byGameId(libraryEntry.id))
                ManualGenreChip(
                  manualGenre.label,
                  onPressed: () => onChipPressed(
                      LibraryFilter(manualGenre: manualGenre.encode())),
                ),
          ],
        ),
      ],
    );
  }
}

/// Tags shows on a LibraryEntry's grid/list card.
class GameCardChips extends StatelessWidget {
  final LibraryEntry libraryEntry;
  final bool includeCompanies;
  final bool includeCollections;

  const GameCardChips({
    super.key,
    required this.libraryEntry,
    this.includeCompanies = false,
    this.includeCollections = true,
  });

  @override
  Widget build(BuildContext context) {
    final tagsModel = context.watch<GameTagsModel>();

    void onChipPressed(LibraryFilter filter) {
      if (context.canPop()) {
        context.pop();
      }
      final updatedFilter =
          context.read<LibraryFilterModel>().filter.add(filter);
      updateLibraryView(context, updatedFilter);
    }

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
                      onPressed: () =>
                          onChipPressed(LibraryFilter(developer: company)),
                    ),
                  ),
                for (final company in libraryEntry.publishers)
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: PublisherChip(
                      company,
                      onPressed: () =>
                          onChipPressed(LibraryFilter(publisher: company)),
                    ),
                  ),
              ],
              if (includeCollections) ...[
                for (final collection in libraryEntry.collections)
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CollectionChip(
                      collection,
                      onPressed: () =>
                          onChipPressed(LibraryFilter(collection: collection)),
                    ),
                  ),
                for (final franchise in libraryEntry.franchises)
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: FranchiseChip(
                      franchise,
                      onPressed: () =>
                          onChipPressed(LibraryFilter(franchise: franchise)),
                    ),
                  ),
              ],
              for (final genre in libraryEntry.digest.espyGenres)
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: EspyGenreChip(
                    genre,
                    onPressed: () =>
                        onChipPressed(LibraryFilter(manualGenre: genre)),
                  ),
                ),
              for (final userTag
                  in tagsModel.userTags.tagsByGameId(libraryEntry.id))
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TagChip(
                    userTag,
                    onPressed: () =>
                        onChipPressed(LibraryFilter(userTag: userTag)),
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
                    onPressed: () => onChipPressed(
                        LibraryFilter(manualGenre: manualGenre.encode())),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
