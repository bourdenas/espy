import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filter.dart';
import 'package:espy/widgets/autocomplete_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
              .read<GameTagsModel>()
              .filterStores(searchTerms)
              .take(4)
              .map(
                (store) => Suggestion(
                  text: store,
                  icon: Icon(
                    Icons.storefront,
                    color: Colors.deepPurpleAccent,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.pushNamed('games',
                        queryParams: LibraryFilter(stores: {store}).params());
                  },
                ),
              ),
          ...context.read<GameTagsModel>().filterTags(searchTerms).take(4).map(
                (tag) => Suggestion(
                  text: tag.name,
                  icon: Icon(
                    Icons.tag,
                    color: tag.color,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.pushNamed('games',
                        queryParams: LibraryFilter(tags: {tag.name}).params());
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
                    Navigator.of(context).pop();
                    context
                        .pushNamed('details', params: {'gid': '${entry.id}'});
                  },
                ),
              ),
          ...context
              .read<GameTagsModel>()
              .filterCollections(searchTerms)
              .take(4)
              .map(
                (collection) => Suggestion(
                  text: collection,
                  icon: Icon(
                    Icons.circle,
                    color: Colors.indigoAccent,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.pushNamed('games',
                        queryParams:
                            LibraryFilter(collections: {collection}).params());
                  },
                ),
              ),
          ...context
              .read<GameTagsModel>()
              .filterCompanies(searchTerms)
              .take(4)
              .map(
                (company) => Suggestion(
                  text: company,
                  icon: Icon(
                    Icons.business,
                    color: Colors.redAccent,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.pushNamed('games',
                        queryParams:
                            LibraryFilter(companies: {company}).params());
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
