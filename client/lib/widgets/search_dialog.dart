import 'package:espy/modules/models/game_library_model.dart';
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
                  return context
                      .read<GameLibraryModel>()
                      .library
                      .entry
                      .where((entry) => entry.game.name
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()))
                      .map((entry) => entry.game.name);
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
                      });
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
