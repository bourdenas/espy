import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/filtering/library_filter.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter_model.dart';
import 'package:espy/modules/models/user_model.dart';
import 'package:espy/pages/espy_navigator.dart';
import 'package:espy/widgets/gametags/espy_chips.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Bar of game chips shows on GameEntry's details page.
class EspyChipsDetailsBar extends StatelessWidget {
  const EspyChipsDetailsBar(this.libraryEntry, {super.key});

  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
    final tagsModel = context.watch<GameTagsModel>();

    return Column(
      children: [
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            for (final company in libraryEntry.developers)
              DeveloperChip(
                company,
                onPressed: () => context
                    .pushNamed('company', pathParameters: {'name': company}),
              ),
            for (final company in libraryEntry.publishers)
              PublisherChip(
                company,
                onPressed: () => context
                    .pushNamed('company', pathParameters: {'name': company}),
              ),
            for (final collection in libraryEntry.collections)
              CollectionChip(
                collection,
                onPressed: () =>
                    addFilter(context, LibraryFilter(collection: collection)),
              ),
            for (final franchise in libraryEntry.franchises)
              FranchiseChip(
                franchise,
                onPressed: () =>
                    addFilter(context, LibraryFilter(franchise: franchise)),
              ),
            for (final genre in libraryEntry.digest.espyGenres)
              EspyGenreChip(
                genre,
                onPressed: () =>
                    addRefinement(context, LibraryFilter(genre: genre)),
              ),
            if (context.watch<UserModel>().isSignedIn)
              for (final tag
                  in tagsModel.userTags.tagsByGameId(libraryEntry.id))
                ManualTagChip(
                  tag,
                  onPressed: () =>
                      addFilter(context, LibraryFilter(userTag: tag)),
                ),
            if (context.watch<UserModel>().isSignedIn)
              for (final manualGenre
                  in tagsModel.manualGenres.byGameId(libraryEntry.id))
                ManualGenreChip(
                  manualGenre.label,
                  onPressed: () => addFilter(context,
                      LibraryFilter(manualGenre: manualGenre.encode())),
                ),
          ],
        ),
        const Padding(padding: EdgeInsets.all(8)),
        GameKeywords(libraryEntry),
      ],
    );
  }
}

class GameKeywords extends StatelessWidget {
  const GameKeywords(this.libraryEntry, {super.key});

  final LibraryEntry libraryEntry;

  @override
  Widget build(BuildContext context) {
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
            for (final keyword in libraryEntry.digest.keywords)
              KeywordChip(
                keyword,
                onPressed: () => onChipPressed(LibraryFilter(keyword: keyword)),
              ),
          ],
        ),
      ],
    );
  }
}

void addFilter(BuildContext context, LibraryFilter filter) {
  if (context.canPop()) {
    context.pop();
  }
  final updatedFilter = context.read<LibraryFilterModel>().filter.add(filter);
  updateLibraryView(context, updatedFilter);
}

void addRefinement(BuildContext context, LibraryFilter filter) {
  if (context.canPop()) {
    context.pop();
  }
  context.read<RefinementModel>().refinement = filter;
}
