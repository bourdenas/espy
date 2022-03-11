import 'package:espy/modules/dialogs/matching/matching_dialog.dart';
import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/widgets/gametags/game_tags.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EntryEditDialog extends StatelessWidget {
  static Future<void> show(BuildContext context, LibraryEntry entry) async {
    showDialog(
      context: context,
      builder: (context) => EntryEditDialog(entry),
    );
  }

  final LibraryEntry entry;

  EntryEditDialog(this.entry);

  @override
  Widget build(BuildContext context) {
    final release =
        DateTime.fromMillisecondsSinceEpoch(entry.releaseDate * 1000);
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              entry.name,
              style: Theme.of(context).textTheme.headline4,
            ),
          ),
          SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GameTags(entry),
          ),
          SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: ExpandablePanel(
                header: Text('Storefronts'),
                collapsed: Container(),
                expanded: _StorefrontDropdown(entry),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorefrontDropdown extends StatefulWidget {
  _StorefrontDropdown(this.entry);

  final LibraryEntry entry;

  @override
  _StorefrontDropdownState createState() =>
      _StorefrontDropdownState(entry.storeEntries[0]);
}

class _StorefrontDropdownState extends State<_StorefrontDropdown> {
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
              for (final storeEntry in widget.entry.storeEntries)
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
                  onPressed: () => onRematch(context),
                  child: Text('Re-match'),
                ),
                ElevatedButton(
                  onPressed: () => onUnmatch(context),
                  child: Text('Unmatch'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onRematch(BuildContext context) {
    MatchingDialog.show(context, storeEntry, onMatch: (gameEntry) {
      context.read<GameLibraryModel>().unmatchEntry(storeEntry, widget.entry);
      Navigator.pushNamed(context, '/details', arguments: '${gameEntry.id}');
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

                if (widget.entry.storeEntries.length == 1) {
                  Navigator.pop(context);
                }

                context
                    .read<GameLibraryModel>()
                    .unmatchEntry(storeEntry, widget.entry);
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
