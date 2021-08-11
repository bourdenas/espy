import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filters_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/autocomplete_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchDialogField extends StatelessWidget {
  const SearchDialogField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AutocompleteField(
      width: 400,
      hintText: 'Search...',
      icon: Icon(Icons.search),
      createSuggestions: (text) {
        final searchTerms = text.toLowerCase().split(' ');
        return [
          ...context
              .read<GameTagsIndex>()
              .tags
              .where((tag) => searchTerms.every((term) => tag
                  .toLowerCase()
                  .split(' ')
                  .any((word) => word.startsWith(term))))
              .take(4)
              .map((tag) => Suggestion(
                  text: tag,
                  icon: Icon(Icons.tag),
                  onTap: () {
                    context.read<LibraryFiltersModel>().clearFilter();
                    context.read<EspyRouterDelegate>().showLibrary();
                    context.read<LibraryFiltersModel>().addTagFilter(tag);
                  })),
          ...context
              .read<GameLibraryModel>()
              .entries
              .where((entry) => searchTerms.every((term) => entry.name
                  .toLowerCase()
                  .split(' ')
                  .any((word) => word.startsWith(term))))
              .take(4)
              .map((entry) => Suggestion(
                  text: entry.name,
                  icon: Icon(Icons.games),
                  onTap: () {
                    context
                        .read<EspyRouterDelegate>()
                        .showGameDetails('${entry.id}');
                  })),
          ...context
              .read<GameTagsIndex>()
              .collections
              .where((collection) => searchTerms.every((term) => collection.name
                  .toLowerCase()
                  .split(' ')
                  .any((word) => word.startsWith(term))))
              .take(4)
              .map((collection) => Suggestion(
                  text: collection.name,
                  icon: Icon(Icons.circle),
                  onTap: () {
                    context.read<LibraryFiltersModel>().clearFilter();
                    context.read<EspyRouterDelegate>().showLibrary();
                    context
                        .read<LibraryFiltersModel>()
                        .addCollectionFilter(collection);
                  })),
          ...context
              .read<GameTagsIndex>()
              .companies
              .where((company) => searchTerms.every((term) => company.name
                  .toLowerCase()
                  .split(' ')
                  .any((word) => word.startsWith(term))))
              .take(4)
              .map((company) => Suggestion(
                  text: company.name,
                  icon: Icon(Icons.business),
                  onTap: () {
                    context.read<LibraryFiltersModel>().clearFilter();
                    context.read<EspyRouterDelegate>().showLibrary();
                    context
                        .read<LibraryFiltersModel>()
                        .addCompanyFilter(company);
                  })),
        ];
      },
    );
  }
}
