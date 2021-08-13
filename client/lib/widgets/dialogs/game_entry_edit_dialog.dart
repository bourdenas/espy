import 'package:espy/modules/documents/library_entry.dart';
import 'package:espy/modules/documents/store_entry.dart';
import 'package:espy/modules/models/game_library_model.dart';
import 'package:espy/modules/routing/espy_router_delegate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GameEntryEditDialog extends StatelessWidget {
  static Future<void> show(BuildContext context, LibraryEntry entry) async {
    showDialog(
      context: context,
      builder: (context) => GameEntryEditDialog(entry),
    );
  }

  final LibraryEntry entry;

  GameEntryEditDialog(this.entry);

  @override
  Widget build(BuildContext context) {
    final release =
        DateTime.fromMillisecondsSinceEpoch(entry.releaseDate * 1000);
    return AlertDialog(
      content: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40.0,
            top: -40.0,
            child: InkResponse(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: CircleAvatar(
                child: Icon(Icons.close),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: TextEditingController()..text = entry.name,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: TextEditingController()
                    ..text = '${release.day}/${release.month}/${release.year} ',
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Release Date',
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _StorefrontDropdown(entry),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorefrontDropdown extends StatefulWidget {
  _StorefrontDropdown(this._entry);

  final LibraryEntry _entry;

  @override
  _StorefrontDropdownState createState() => _StorefrontDropdownState(_entry);
}

class _StorefrontDropdownState extends State<_StorefrontDropdown> {
  _StorefrontDropdownState(this._entry) : _chosenValue = _entry.storeEntries[0];

  final LibraryEntry _entry;
  StoreEntry _chosenValue;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      child: Column(
        children: [
          DropdownButton<StoreEntry>(
            value: _chosenValue,
            items: [
              for (final storeEntry in _entry.storeEntries)
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
                _chosenValue = value!;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: TextEditingController()..text = _chosenValue.title,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Store Title',
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text(
                            'Are you sure you want to unmatch this store entry?'),
                        actions: [
                          TextButton(
                              onPressed: () async {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        "Unmatching '${_chosenValue.title}'...")));
                                Navigator.of(context).pop();

                                if (_entry.storeEntries.length == 1) {
                                  context
                                      .read<EspyRouterDelegate>()
                                      .showLibrary();
                                }

                                context
                                    .read<GameLibraryModel>()
                                    .unmatchEntry(_chosenValue, _entry);
                                Navigator.pop(context);
                              },
                              child: Text('Confirm')),
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Cancel')),
                        ],
                      );
                    });
              },
              child: Text('Unmatch'),
            ),
          ),
        ],
      ),
    );
  }
}
