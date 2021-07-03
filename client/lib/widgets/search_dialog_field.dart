import 'package:espy/modules/models/game_details_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/library_filters_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchDialogField extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SearchDialogFieldState();
}

class SearchDialogFieldState extends State<SearchDialogField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _suggestionsLayerLink = LayerLink();
  OverlayEntry? _suggestionsOverlay;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _suggestionsLayerLink,
      child: Container(
        width: 400,
        child: TextField(
          onSubmitted: (term) => setState(() {
            _matchSearchTerm(term);
          }),
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search...',
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (_suggestionsOverlay != null) {
        _suggestionsOverlay!.remove();
        _suggestionsOverlay = null;
      }

      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        final suggestions = [
          ...context
              .read<GameLibraryModel>()
              .library
              .entry
              .where(
                  (entry) => entry.game.name.toLowerCase().contains(searchTerm))
              .take(4)
              .map((entry) => _Suggestion(entry.game.name, Icons.games, () {
                    context
                        .read<EspyRouterDelegate>()
                        .showGameDetails('${entry.game.id}');
                  })),
          ...context
              .read<GameDetailsModel>()
              .tags
              .where((tag) => tag.toLowerCase().contains(searchTerm))
              .take(4)
              .map((tag) => _Suggestion(tag, Icons.tag, () {
                    context.read<LibraryFiltersModel>().clearFilter();
                    context.read<EspyRouterDelegate>().showLibrary();
                    context.read<LibraryFiltersModel>().addTagFilter(tag);
                  })),
          ...context
              .read<GameDetailsModel>()
              .collections
              .where((collection) =>
                  collection.name.toLowerCase().contains(searchTerm))
              .take(4)
              .map(
                  (collection) => _Suggestion(collection.name, Icons.label, () {
                        context.read<LibraryFiltersModel>().clearFilter();
                        context.read<EspyRouterDelegate>().showLibrary();
                        context
                            .read<LibraryFiltersModel>()
                            .addCollectionFilter(collection);
                      })),
          ...context
              .read<GameDetailsModel>()
              .companies
              .where(
                  (company) => company.name.toLowerCase().contains(searchTerm))
              .take(4)
              .map((company) => _Suggestion(company.name, Icons.business, () {
                    context.read<LibraryFiltersModel>().clearFilter();
                    context.read<EspyRouterDelegate>().showLibrary();
                    context
                        .read<LibraryFiltersModel>()
                        .addCompanyFilter(company);
                  })),
        ];

        _suggestionsOverlay = _createSuggestions(suggestions);
        Overlay.of(context)!.insert(_suggestionsOverlay!);
      }
    });

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _suggestionsOverlay != null) {
        _suggestionsOverlay!.remove();
        _suggestionsOverlay = null;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  OverlayEntry _createSuggestions(Iterable<_Suggestion> suggestions) {
    final size = context.size!;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _suggestionsLayerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final suggestion in suggestions)
                  ListTile(
                    leading: Icon(suggestion.icon),
                    title: Text(suggestion.text),
                    onTap: () => _invokeSuggestion(suggestion),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _invokeSuggestion(_Suggestion suggestion) {
    suggestion.invoke();
    Navigator.of(context).pop();
  }

  void _matchSearchTerm(String term) {
    if (term.isEmpty) {
      _searchFocusNode.requestFocus();
      return;
    }

    print(term);

    // TODO: Correct condition should be if term has a match.
    if (term.isNotEmpty) {
      Navigator.of(context).pop();
    } else {
      _searchController.clear();
      _searchFocusNode.requestFocus();
    }
  }
}

class _Suggestion {
  final String text;
  final IconData icon;
  final Function invoke;

  const _Suggestion(
    this.text,
    this.icon,
    this.invoke,
  );
}
