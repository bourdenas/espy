import 'package:flutter/material.dart';

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
            child: Autocomplete<String>(
              optionsBuilder: (textEditingValue) {
                if (textEditingValue.text == '') {
                  return const [];
                }
                return ['Diablo', 'Baldurs Gate 3', 'Civilization'].where(
                    (title) => title
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
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
            ),
          ),
        ],
      ),
    );
  }
}
