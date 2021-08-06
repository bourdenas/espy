import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/models/game_tags_model.dart';
import 'package:espy/modules/models/library_filters_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        child: RawKeyboardListener(
          key: UniqueKey(),
          focusNode: _searchFocusNode,
          onKey: handleKey,
          child: TextField(
            key: UniqueKey(),
            onSubmitted: (term) => setState(() {
              _matchSearchTerm(term);
            }),
            controller: _searchController,
            // focusNode: _searchFocusNode,
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search...',
            ),
          ),
        ),
      ),
    );
  }

  void handleKey(RawKeyEvent key) {
    if (key.runtimeType == RawKeyDownEvent) {
      if (key.data.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1) % _suggestions.length;
        });
      } else if (key.data.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
        });
      }
    }
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
        final searchTerms = _searchController.text.toLowerCase().split(' ');
        final suggestions = [
          ...context
              .read<GameTagsIndex>()
              .tags
              .where((tag) => searchTerms.every((term) => tag
                  .toLowerCase()
                  .split(' ')
                  .any((word) => word.startsWith(term))))
              .take(4)
              .map((tag) => _Suggestion(
                  text: tag,
                  icon: Icons.tag,
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
              .map((entry) => _Suggestion(
                  text: entry.name,
                  icon: Icons.games,
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
              .map((collection) => _Suggestion(
                  text: collection.name,
                  icon: Icons.circle,
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
              .map((company) => _Suggestion(
                  text: company.name,
                  icon: Icons.business,
                  onTap: () {
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

  OverlayEntry _createSuggestions(List<_Suggestion> suggestions) {
    final size = context.size!;
    _suggestions = suggestions;

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
              children: suggestions
                  .asMap()
                  .entries
                  .map<ListTile>((entry) => ListTile(
                        leading: Icon(entry.value.icon),
                        title: Text(entry.value.text),
                        onTap: () => _invokeSuggestion(entry.value),
                        selected: entry.key == _selectedIndex,
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  var _selectedIndex = 0;
  var _suggestions = [];

  void _invokeSuggestion(_Suggestion suggestion) {
    suggestion.onTap();
    Navigator.of(context).pop();
  }

  void _matchSearchTerm(String term) {
    if (term.isEmpty) {
      _searchFocusNode.requestFocus();
      return;
    }

    if (_selectedIndex < _suggestions.length) {
      _suggestions[_selectedIndex].onTap();
    }
    Navigator.of(context).pop();
  }
}

class _Suggestion {
  final String text;
  final IconData icon;
  final Function onTap;

  const _Suggestion({
    required this.text,
    required this.icon,
    required this.onTap,
  });
}
