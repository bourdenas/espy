import 'dart:js';

import 'package:espy/modules/models/game_details_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/proto/igdbapi.pb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _SearchOption {
  final String text;
  final IconData icon;

  const _SearchOption(this.text, this.icon);
}

class SearchDialog extends StatelessWidget {
  static Future<void> show(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => SearchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 400,
              child: Autocomplete<_SearchOption>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const [];
                  }
                  return [
                    ...context
                        .read<GameLibraryModel>()
                        .library
                        .entry
                        .where((entry) => entry.game.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()))
                        .map((entry) => entry.game.name)
                        .take(4)
                        .map((entry) => _SearchOption(entry, Icons.games)),
                    ...context
                        .read<GameDetailsModel>()
                        .tags
                        .where((tag) => tag
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()))
                        .take(4)
                        .map((tag) => _SearchOption(tag, Icons.tag)),
                    ...context
                        .read<GameDetailsModel>()
                        .collections
                        .where((collection) => collection.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()))
                        .map((collection) => collection.name)
                        .take(4)
                        .map((collection) => _SearchOption(
                            collection, Icons.branding_watermark)),
                    ...context
                        .read<GameDetailsModel>()
                        .companies
                        .where((company) => company.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()))
                        .map((company) => company.name)
                        .take(4)
                        .map((company) =>
                            _SearchOption(company, Icons.business)),
                  ];
                },
                displayStringForOption: (option) {
                  return option.text;
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Material(
                    elevation: 4.0,
                    child: Container(
                      width: 300,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: [
                          for (final option in options)
                            ListTile(
                              leading: Icon(option.icon),
                              title: Text(option.text),
                              onTap: () => onSelected(option),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                fieldViewBuilder: (context, textEditingController, focusNode,
                    onFieldSubmitted) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search...',
                    ),
                  );
                },
                onSelected: (selection) => print(selection.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
