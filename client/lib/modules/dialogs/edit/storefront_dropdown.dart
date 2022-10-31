import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StorefrontDropdown extends StatefulWidget {
  StorefrontDropdown(this.libraryEntry);

  final LibraryEntry libraryEntry;

  @override
  _StorefrontDropdownState createState() =>
      _StorefrontDropdownState(libraryEntry.storeEntries[0]);
}

class _StorefrontDropdownState extends State<StorefrontDropdown> {
  _StorefrontDropdownState(this.storeEntry);

  StoreEntry storeEntry;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      child: Column(
        children: [
          DropdownButton<StoreEntry>(
            value: storeEntry,
            items: [
              for (final storeEntry in widget.libraryEntry.storeEntries)
                DropdownMenuItem<StoreEntry>(
                  value: storeEntry,
                  child: Text(storeEntry.storefront),
                ),
            ],
            hint: Text(
              "Storefront selection",
            ),
            onChanged: (StoreEntry? value) {
              setState(() {
                storeEntry = value!;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: TextEditingController()..text = storeEntry.title,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Store Title',
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: Text('Re-match'),
                  onPressed: () => onRematch(context),
                ),
                ElevatedButton(
                  child: Text('Unmatch'),
                  onPressed: () => onUnmatch(context),
                ),
                ElevatedButton(
                  child: Text('Delete'),
                  onPressed: () => onDelete(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onRematch(BuildContext context) {
    MatchingDialog.show(context, storeEntry: storeEntry, onMatch: (gameEntry) {
      context
          .read<GameLibraryModel>()
          .rematchEntry(storeEntry, widget.libraryEntry, gameEntry);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    });
  }

  void onUnmatch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text('Are you sure you want to unmatch this entry?'),
          actions: [
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Unmatching '${storeEntry.title}'...")));
                Navigator.of(context).pop();

                if (widget.libraryEntry.storeEntries.length == 1) {
                  Navigator.pop(context);
                }

                context
                    .read<GameLibraryModel>()
                    .unmatchEntry(storeEntry, widget.libraryEntry);
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void onDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text('Are you sure you want to delete this entry?'),
          actions: [
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Deleting '${storeEntry.title}'...")));
                Navigator.of(context).pop();

                if (widget.libraryEntry.storeEntries.length == 1) {
                  Navigator.pop(context);
                }

                context.read<GameLibraryModel>().unmatchEntry(
                    storeEntry, widget.libraryEntry,
                    delete: true);
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
