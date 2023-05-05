import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/user_library_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class StorefrontDropdown extends StatefulWidget {
  const StorefrontDropdown(this.libraryEntry, {Key? key}) : super(key: key);

  final LibraryEntry libraryEntry;

  @override
  StorefrontDropdownState createState() => StorefrontDropdownState();
}

class StorefrontDropdownState extends State<StorefrontDropdown> {
  @override
  Widget build(BuildContext context) {
    StoreEntry storeEntry = widget.libraryEntry.storeEntries[0];

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
            hint: const Text(
              'Storefront selection',
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
              decoration: const InputDecoration(
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
                  child: const Text('Re-match'),
                  onPressed: () => onRematch(context),
                ),
                ElevatedButton(
                  child: const Text('Unmatch'),
                  onPressed: () => onUnmatch(context),
                ),
                ElevatedButton(
                  child: const Text('Delete'),
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
    MatchingDialog.show(
      context,
      storeEntry: widget.libraryEntry.storeEntries[0],
      onMatch: (storeEntry, gameEntry) {
        context
            .read<UserLibraryModel>()
            .rematchEntry(storeEntry, widget.libraryEntry, gameEntry);
        context.pushNamed('details', params: {'gid': '${gameEntry.id}'});
      },
    );
  }

  void onUnmatch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const Text('Are you sure you want to unmatch this entry?'),
          actions: [
            TextButton(
              child: const Text('Confirm'),
              onPressed: () async {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "Unmatching '${widget.libraryEntry.storeEntries[0].title}'...")));
                Navigator.of(context).pop();

                if (widget.libraryEntry.storeEntries.length == 1) {
                  Navigator.pop(context);
                }

                context.read<UserLibraryModel>().unmatchEntry(
                    widget.libraryEntry.storeEntries[0], widget.libraryEntry);
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
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
          content: const Text('Are you sure you want to delete this entry?'),
          actions: [
            TextButton(
              child: const Text('Confirm'),
              onPressed: () async {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "Deleting '${widget.libraryEntry.storeEntries[0].title}'...")));
                Navigator.of(context).pop();

                if (widget.libraryEntry.storeEntries.length == 1) {
                  Navigator.pop(context);
                }

                context.read<UserLibraryModel>().unmatchEntry(
                    widget.libraryEntry.storeEntries[0], widget.libraryEntry,
                    delete: true);
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
