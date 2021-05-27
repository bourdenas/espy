import 'dart:js';

import 'package:espy/modules/models/game_details_model.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/proto/igdbapi.pb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              child: Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const [];
                  }
                  return [
                    ...context
                        .read<GameDetailsModel>()
                        .tags
                        .where((tag) => tag
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()))
                        .take(4),
                    ...context
                        .read<GameDetailsModel>()
                        .collections
                        .where((collection) => collection.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()))
                        .map((collection) => collection.name)
                        .take(4),
                    ...context
                        .read<GameDetailsModel>()
                        .companies
                        .where((company) => company.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()))
                        .map((company) => company.name)
                        .take(4),
                    ...context
                        .read<GameLibraryModel>()
                        .library
                        .entry
                        .where((entry) => entry.game.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()))
                        .map((entry) => entry.game.name)
                        .take(4),
                  ];
                },
                fieldViewBuilder: (context, textEditingController, focusNode,
                    onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search...',
                    ),
                    onFieldSubmitted: (String value) {
                      onFieldSubmitted();
                    },
                  );
                },
                onSelected: (selection) => print(selection),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
