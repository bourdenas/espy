import 'package:espy/modules/dialogs/search/search_dialog_field.dart';
import 'package:flutter/material.dart';

class SearchDialog extends StatelessWidget {
  static void show(BuildContext context) {
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
            child: SearchDialogField(),
          ),
        ],
      ),
    );
  }
}
