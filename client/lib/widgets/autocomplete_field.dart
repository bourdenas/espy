import 'package:flutter/material.dart';

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

class AutocompleteField extends StatelessWidget {
  final double width;
  final String hintText;
  final Icon? icon;
  final List<Suggestion> Function(String text) createSuggestions;
  final void Function(String text, Suggestion? suggestion) onSubmit;

  AutocompleteField({
    Key? key,
    required this.width,
    required this.hintText,
    required this.createSuggestions,
    required this.onSubmit,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      child: Autocomplete<Suggestion>(
        displayStringForOption: (Suggestion suggestoin) => suggestoin.text,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text == '') {
            return const {};
          }
          return createSuggestions(textEditingValue.text);
        },
        onSelected: (Suggestion selection) {
          onSubmit(selection.text, selection);
        },
        fieldViewBuilder: (BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted) {
          return TextFormField(
            decoration: InputDecoration(
              prefixIcon: icon,
              hintText: hintText,
            ),
            controller: textEditingController,
            focusNode: focusNode,
            onFieldSubmitted: (String value) {
              onFieldSubmitted();
              textEditingController.text = '';
            },
          );
        },
      ),
    );
  }
}
