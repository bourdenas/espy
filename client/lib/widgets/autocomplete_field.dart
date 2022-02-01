import 'package:espy/modules/models/app_config_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Suggestion {
  final String text;
  final Icon? icon;
  final Function onTap;

  const Suggestion({
    required this.text,
    required this.onTap,
    this.icon,
  });
}

class AutocompleteField extends StatefulWidget {
  final double width;
  final String hintText;
  final Icon? icon;
  final List<Suggestion> Function(String text) createSuggestions;
  final void Function(String text, Suggestion? suggestion) onSubmit;

  AutocompleteField({
    required this.width,
    required this.hintText,
    required this.createSuggestions,
    required this.onSubmit,
    this.icon,
  });

  @override
  State<StatefulWidget> createState() => AutocompleteFieldState(
        width: width,
        hintText: hintText,
        createSuggestions: createSuggestions,
        onSubmit: onSubmit,
        icon: icon,
      );
}

class AutocompleteFieldState extends State<AutocompleteField> {
  final double width;
  final String hintText;
  final Icon? icon;
  final List<Suggestion> Function(String) createSuggestions;
  final void Function(String text, Suggestion? suggestion) onSubmit;

  AutocompleteFieldState({
    required this.width,
    required this.hintText,
    required this.createSuggestions,
    required this.onSubmit,
    this.icon,
  });

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _suggestionsLayerLink = LayerLink();
  OverlayEntry? _suggestionsOverlay;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _suggestionsLayerLink,
      child: Container(
        width: width,
        child: RawKeyboardListener(
          key: UniqueKey(),
          focusNode: _searchFocusNode,
          onKey: handleKey,
          child: TextField(
            key: UniqueKey(),
            onSubmitted: (term) => _submit(term),
            controller: _searchController,
            // focusNode: _searchFocusNode,
            autofocus: !context.read<AppConfigModel>().isMobile(context),
            decoration: InputDecoration(
              prefixIcon: icon,
              hintText: hintText,
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
        _suggestionsOverlay = _createSuggestionsOverlay(
            createSuggestions(_searchController.text));
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

  OverlayEntry _createSuggestionsOverlay(List<Suggestion> suggestions) {
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
                        leading: entry.value.icon,
                        title: Text(entry.value.text),
                        onTap: () => entry.value.onTap(),
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

  void _submit(String term) {
    onSubmit(
        term,
        _selectedIndex < _suggestions.length
            ? _suggestions[_selectedIndex]
            : null);

    _searchController.clear();
    _searchFocusNode.requestFocus();
  }
}
