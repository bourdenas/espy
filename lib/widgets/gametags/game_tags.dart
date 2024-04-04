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
                    onChipPressed(LibraryFilter(developers: {company})),
              ),
            for (final company in libraryEntry.publishers)
              PublisherChip(
                company,
                onPressed: () =>
                    onChipPressed(LibraryFilter(publishers: {company})),
              ),
            for (final collection in libraryEntry.collections)
              CollectionChip(
                collection,
                onPressed: () =>
                    onChipPressed(LibraryFilter(collections: {collection})),
              ),
            for (final franchise in libraryEntry.franchises)
              FranchiseChip(
                franchise,
                onPressed: () =>
                    onChipPressed(LibraryFilter(franchises: {franchise})),
              ),
            for (final genreTag
                in tagsModel.genreTags.byGameId(libraryEntry.id))
              GenreTagChip(
                genreTag.name,
                onPressed: () => onChipPressed(
                    LibraryFilter(genreTags: {genreTag.encode()})),
              ),
            if (context.watch<UserModel>().isSignedIn)
              for (final tag in tagsModel.userTags.byGameId(libraryEntry.id))
                TagChip(
                  tag,
                  onPressed: () =>
                      onChipPressed(LibraryFilter(tags: {tag.name})),
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

    return SizedBox(
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
                      onChipPressed(LibraryFilter(developers: {company})),
                ),
              ),
            for (final company in libraryEntry.publishers)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: PublisherChip(
                  company,
                  onPressed: () =>
                      onChipPressed(LibraryFilter(publishers: {company})),
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
                      onChipPressed(LibraryFilter(collections: {collection})),
                ),
              ),
            for (final franchise in libraryEntry.franchises)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: FranchiseChip(
                  franchise,
                  onPressed: () =>
                      onChipPressed(LibraryFilter(franchises: {franchise})),
                ),
              ),
          ],
          for (final genreTag in tagsModel.genreTags.byGameId(libraryEntry.id))
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: GenreTagChip(
                genreTag.name,
                onPressed: () => onChipPressed(
                    LibraryFilter(genreTags: {genreTag.encode()})),
              ),
            ),
          for (final tag in tagsModel.userTags.byGameId(libraryEntry.id))
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: TagChip(
                tag,
                onPressed: () => onChipPressed(LibraryFilter(tags: {tag.name})),
              ),
            ),
        ],
      ),
    );
  }
}
