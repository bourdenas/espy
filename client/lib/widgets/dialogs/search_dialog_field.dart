import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/filters_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:espy/widgets/autocomplete_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchDialogField extends StatelessWidget {
  const SearchDialogField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.read<GameLibraryModel>().fetchAll();

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
              .where(
                (tag) => searchTerms.every((term) => tag
                    .toLowerCase()
                    .split(' ')
                    .any((word) => word.startsWith(term))),
              )
              .take(4)
              .map(
                (tag) => Suggestion(
                  text: tag,
                  icon: Icon(Icons.tag),
                  onTap: () {
                    context.read<FiltersModel>().clearFilter();
                    context.read<EspyRouterDelegate>().showLibrary();
                    context.read<FiltersModel>().addTagFilter(tag);
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ...context
              .read<GameLibraryModel>()
              .entries
              .where((entry) => searchTerms.every((term) => entry.name
                  .toLowerCase()
                  .split(' ')
                  .any((word) => word.startsWith(term))))
              .take(4)
              .map(
                (entry) => Suggestion(
                  text: entry.name,
                  icon: Icon(Icons.games),
                  onTap: () {
                    context
                        .read<EspyRouterDelegate>()
                        .showGameDetails('${entry.id}');
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ...context
              .read<GameTagsIndex>()
              .collections
              .where((collection) => searchTerms.every((term) => collection.name
                  .toLowerCase()
                  .split(' ')
                  .any((word) => word.startsWith(term))))
              .take(4)
              .map(
                (collection) => Suggestion(
                  text: collection.name,
                  icon: Icon(Icons.circle),
                  onTap: () {
                    context.read<FiltersModel>().clearFilter();
                    context.read<EspyRouterDelegate>().showLibrary();
                    context
                        .read<FiltersModel>()
                        .addCollectionFilter(collection);
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ...context
              .read<GameTagsIndex>()
              .companies
              .where((company) => searchTerms.every((term) => company.name
                  .toLowerCase()
                  .split(' ')
                  .any((word) => word.startsWith(term))))
              .take(4)
              .map(
                (company) => Suggestion(
                  text: company.name,
                  icon: Icon(Icons.business),
                  onTap: () {
                    context.read<FiltersModel>().clearFilter();
                    context.read<EspyRouterDelegate>().showLibrary();
                    context.read<FiltersModel>().addCompanyFilter(company);
                    Navigator.of(context).pop();
                  },
                ),
              ),
        ];
      },
      onSubmit: (text, suggestion) {
        suggestion?.onTap();
      },
    );
  }
}
